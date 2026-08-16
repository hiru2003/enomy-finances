<?php
error_reporting(E_ALL);
ini_set('display_errors', 0);

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=UTF-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$db_host = 'localhost';
$db_name = 'enomy_finances';
$db_user = 'root';
$db_pass = '80548755';

try {
    $pdo = new PDO("mysql:host={$db_host};dbname={$db_name};charset=utf8mb4", $db_user, $db_pass, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'status'  => 'error',
        'message' => 'Database connection failed: ' . $e->getMessage()
    ]);
    exit();
}

$action = $_GET['action'] ?? '';
$inputData = json_decode(file_get_contents('php://input'), true) ?? $_POST;

switch ($action) {
    case 'getClients':
        try {
            $stmt = $pdo->query("
                SELECT 
                    c.CustomerID AS id,
                    c.FullName AS name,
                    c.Email AS email,
                    c.Phone AS phone,
                    c.CreatedAt AS createdAt,
                    COUNT(t.TransactionID) AS txCount
                FROM Customer c
                LEFT JOIN Transaction t ON c.CustomerID = t.CustomerID
                GROUP BY c.CustomerID, c.FullName, c.Email, c.Phone, c.CreatedAt
                ORDER BY c.CreatedAt DESC
            ");
            $clients = $stmt->fetchAll();
            foreach ($clients as &$client) {
                $client['txCount'] = (int)$client['txCount'];
            }
            echo json_encode(['status' => 'success', 'data' => $clients]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
        break;

    case 'saveClient':
        $id    = trim($inputData['id'] ?? '');
        $name  = trim($inputData['name'] ?? '');
        $email = trim($inputData['email'] ?? '');
        $phone = trim($inputData['phone'] ?? '');

        if (empty($name) || empty($email) || empty($phone)) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'All fields (name, email, phone) are required.']);
            exit();
        }

        try {
            if (!empty($id)) {
                $stmt = $pdo->prepare("
                    UPDATE Customer 
                    SET FullName = :name, Email = :email, Phone = :phone 
                    WHERE CustomerID = :id
                ");
                $stmt->execute([':name' => $name, ':email' => $email, ':phone' => $phone, ':id' => $id]);
                echo json_encode(['status' => 'success', 'message' => 'Client updated successfully.', 'id' => $id]);
            } else {
                $newId = 'CL-' . rand(100, 999);
                $stmt  = $pdo->prepare("
                    INSERT INTO Customer (CustomerID, FullName, Email, Phone) 
                    VALUES (:id, :name, :email, :phone)
                ");
                $stmt->execute([':id' => $newId, ':name' => $name, ':email' => $email, ':phone' => $phone]);
                echo json_encode(['status' => 'success', 'message' => 'Client created successfully.', 'id' => $newId]);
            }
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
        break;

    case 'deleteClient':
        $id = trim($inputData['id'] ?? $_GET['id'] ?? '');

        if (empty($id)) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Client ID is required.']);
            exit();
        }

        try {
            $pdo->prepare("DELETE FROM Transaction WHERE CustomerID = :id")->execute([':id' => $id]);
            $pdo->prepare("DELETE FROM InvestmentQuote WHERE CustomerID = :id")->execute([':id' => $id]);
            $stmt = $pdo->prepare("DELETE FROM Customer WHERE CustomerID = :id");
            $stmt->execute([':id' => $id]);
            echo json_encode(['status' => 'success', 'message' => 'Client deleted successfully.']);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
        break;

    case 'addTransaction':
        $customerID  = trim($inputData['customerID'] ?? 'CL-101');
        $initialCurr = trim($inputData['initialCurrency'] ?? 'GBP');
        $targetCurr  = trim($inputData['targetCurrency'] ?? 'USD');
        $amount      = (float)($inputData['amount'] ?? 0);
        $feeApplied  = (float)($inputData['feeApplied'] ?? 0);
        $finalAmount = (float)($inputData['finalAmount'] ?? 0);

        $txID = 'TXN-' . date('Y') . '-' . sprintf('%04d', rand(1, 9999));

        try {
            $stmt = $pdo->prepare("
                INSERT INTO Transaction 
                (TransactionID, CustomerID, InitialCurrency, TargetCurrency, Amount, FeeApplied, FinalAmount)
                VALUES (:txID, :customerID, :initialCurr, :targetCurr, :amount, :feeApplied, :finalAmount)
            ");
            $stmt->execute([
                ':txID'        => $txID,
                ':customerID'  => $customerID,
                ':initialCurr' => $initialCurr,
                ':targetCurr'  => $targetCurr,
                ':amount'      => $amount,
                ':feeApplied'  => $feeApplied,
                ':finalAmount' => $finalAmount,
            ]);
            echo json_encode(['status' => 'success', 'message' => 'Transaction recorded.', 'txID' => $txID]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
        break;

    case 'getCurrencies':
        try {
            $stmt = $pdo->query("SELECT CurrencyCode, ExchangeRate, LastUpdated FROM Currency");
            echo json_encode(['status' => 'success', 'data' => $stmt->fetchAll()]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
        break;

    default:
        http_response_code(400);
        echo json_encode([
            'status'  => 'error',
            'message' => 'Invalid or missing action parameter.'
        ]);
        break;
}
