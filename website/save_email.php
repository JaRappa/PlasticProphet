<?php
header("Content-Type: application/json");

// Path to JSON file (fixed, not influenced by user input)
$file = __DIR__ . "/data/waitlist.json";

// Only allow POST
if (empty($_SERVER['REQUEST_METHOD']) || strtoupper($_SERVER['REQUEST_METHOD']) !== 'POST') {
    http_response_code(405);
    echo json_encode(["ok" => false, "error" => "Method Not Allowed"]);
    exit;
}

// Get email from POST request and normalize
$email = isset($_POST["email"]) ? trim((string)$_POST["email"]) : "";

// Basic length check (RFC limit is 254, but use a reasonable cap)
if ($email === '' || strlen($email) > 254) {
    echo json_encode(["ok" => false, "error" => "Invalid email"]);
    exit;
}

// Remove any CR/LF to prevent header injection if this value is later used in email headers
$email = preg_replace('/[\r\n]+/', '', $email);

// Normalize case (emails are typically compared case-insensitively for local-part portability)
$email = mb_strtolower($email, 'UTF-8');

// Validate email format
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(["ok" => false, "error" => "Invalid email"]);
    exit;
}

// Ensure data directory exists
$dir = dirname($file);
if (!is_dir($dir)) {
    if (!mkdir($dir, 0755, true) && !is_dir($dir)) {
        echo json_encode(["ok" => false, "error" => "Server error"]);
        exit;
    }
}

// Use an exclusive lock and perform read-modify-write to avoid race conditions
$fp = fopen($file, 'c+'); // create if not exists
if ($fp === false) {
    echo json_encode(["ok" => false, "error" => "Server error"]);
    exit;
}

if (!flock($fp, LOCK_EX)) {
    fclose($fp);
    echo json_encode(["ok" => false, "error" => "Server busy"]);
    exit;
}

// Read current contents
$contents = stream_get_contents($fp);
$list = json_decode($contents, true);
if (!is_array($list)) $list = [];

// Avoid duplicates
if (!in_array($email, $list, true)) {
    $list[] = $email;

    // Write back atomically within the lock
    rewind($fp);
    ftruncate($fp, 0);
    $written = fwrite($fp, json_encode($list, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
    fflush($fp);
    if ($written === false) {
        flock($fp, LOCK_UN);
        fclose($fp);
        echo json_encode(["ok" => false, "error" => "Server error"]);
        exit;
    }
}

flock($fp, LOCK_UN);
fclose($fp);

echo json_encode(["ok" => true]);
