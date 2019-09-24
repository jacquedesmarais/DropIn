<?php
require '../vendor/autoload.php';

 $gateway = new Braintree_Gateway([
	'environment' => 'sandbox',
    'merchantId' => 'your_merchant_id',
    'publicKey' => 'your_public_key',
    'privateKey' => 'your_private_key'
]);

 $paymentMethodNonce =  $_POST['payment_method_nonce'];
 $amount = $_POST['amount'];
 
 $result = $gateway->transaction()->sale([
  'amount' => $amount,
  'paymentMethodNonce' => $paymentMethodNonce,
  'options' => [
  	'submitForSettlement' => True
  ]
	]);
 
 echo json_encode($result);
 ?>
