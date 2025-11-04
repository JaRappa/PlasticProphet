<?php
header("Content-Type: application/json");

// Path to JSON file
$file = __DIR__ . "/data/waitlist.json";

// Get email from POST request
$email = isset($_POST["email"]) ? trim($_POST["email"]) : "";

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(["ok" => false, "error" => "Invalid email"]);
    exit;
}

// Load existing emails
$list = json_decode(file_get_contents($file), true);
if (!is_array($list)) $list = [];

// Avoid duplicates
if (!in_array($email, $list)) {
    $list[] = $email;
    file_put_contents($file, json_encode($list, JSON_PRETTY_PRINT));
}

echo json_encode(["ok" => true]);
