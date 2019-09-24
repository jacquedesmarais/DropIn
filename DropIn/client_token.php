<?php
require '../vendor/autoload.php';
    
$gateway = new Braintree_Gateway([
	'environment' => 'sandbox',
	'merchantId' => 'your_merchant_id',
	'publicKey' => 'your_public_key',
	'privateKey' => 'your_private_key'
]);

 $clientToken = $gateway->clientToken()->generate();
 	echo ($clientToken);
?>
