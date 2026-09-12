<?php
// contact.php — handles the khzaen.com contact form submission.

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit;
}

// Honeypot field — real visitors never fill this in, since it's hidden via CSS.
// Bots that auto-fill every field will trip it. Pretend success so they move on.
if (!empty($_POST['website'])) {
    echo json_encode(['success' => true]);
    exit;
}

function clean_field($value) {
    $value = trim($value ?? '');
    // Strip newlines/carriage returns to prevent header injection if this value
    // is ever used in an email header.
    return str_replace(["\r", "\n"], '', $value);
}

$name    = clean_field($_POST['name'] ?? '');
$email   = clean_field($_POST['email'] ?? '');
$role    = clean_field($_POST['role'] ?? '');
$message = trim($_POST['message'] ?? ''); // body text, newlines are fine here

if ($name === '' || $email === '' || $message === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing required fields']);
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Invalid email address']);
    exit;
}

$role_labels = [
    'investor' => 'Investor',
    'project'  => 'Project owner',
    'other'    => 'Other',
];
$role_label = $role_labels[$role] ?? 'Not specified';

$to      = 'info@khzaen.com';
$subject = 'New website inquiry from ' . $name . ' (' . $role_label . ')';

$body  = "New contact form submission from khzaen.com\n\n";
$body .= "Name: {$name}\n";
$body .= "Email: {$email}\n";
$body .= "I am a: {$role_label}\n\n";
$body .= "Message:\n{$message}\n";

// From: uses your own domain (required by most mail servers to avoid being
// flagged as spam). Reply-To is the visitor's address, so hitting "Reply"
// in your inbox goes straight back to them.
$headers   = [];
$headers[] = 'From: Khzaen Website <no-reply@khzaen.com>';
$headers[] = 'Reply-To: ' . $name . ' <' . $email . '>';
$headers[] = 'MIME-Version: 1.0';
$headers[] = 'Content-Type: text/plain; charset=UTF-8';

$sent = mail($to, $subject, $body, implode("\r\n", $headers));

if ($sent) {
    echo json_encode(['success' => true]);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Could not send message']);
}
