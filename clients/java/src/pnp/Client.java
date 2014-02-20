package pnp;

import java.net.MalformedURLException;
import java.util.HashMap;
import java.util.Map;

public class Client extends BaseClient {
	
	public Client(String host, String user, String password) throws MalformedURLException {
		super(host, user, password);
	}
	
	public String userFundsReceived(String transactionId, String referenceUrl, String description, String userId, String depositAmount, String userFunds, String gatewayFee) throws ClientException {
		Map<String, String> eventData = new HashMap<String, String>();
		eventData.put("transaction_id", transactionId);
		eventData.put("reference_url", referenceUrl);
		eventData.put("description", description);
		eventData.put("user_id", userId);
		eventData.put("deposit_amount", depositAmount);
		eventData.put("user_funds", userFunds);
		eventData.put("gateway_fee", gatewayFee);
		
		return this.trigger("user_funds_received", eventData);
	}
	
	public String userRippleWalletFunded(String transactionId, String referenceUrl, String description, String userId, String amount) throws ClientException {
		Map<String, String> eventData = new HashMap<String, String>();
		eventData.put("transaction_id", transactionId);
		eventData.put("reference_url", referenceUrl);
		eventData.put("description", description);
		eventData.put("user_id", userId);
		eventData.put("amount", amount);
		
		return this.trigger("user_ripple_wallet_funded", eventData);
	}
	
	public String bankToRippleWallet(String transactionId, String referenceUrl, String description, String amount) throws ClientException {
		Map<String, String> eventData = new HashMap<String, String>();
		eventData.put("transaction_id", transactionId);
		eventData.put("reference_url", referenceUrl);
		eventData.put("description", description);
		eventData.put("amount", amount);
		
		return this.trigger("bank_to_ripple_wallet", eventData);
	}
	
	public String userFundsTransferredOutOfBank(String transactionId, String referenceUrl, String description, String userId, String totalAmount, String transferAmount, String gatewayFee) throws ClientException {
		Map<String, String> eventData = new HashMap<String, String>();
		eventData.put("transaction_id", transactionId);
		eventData.put("reference_url", referenceUrl);
		eventData.put("description", description);
		eventData.put("user_id", userId);
		eventData.put("total_amount", totalAmount);
		eventData.put("transfer_amount", transferAmount);
		eventData.put("gateway_fee", gatewayFee);
		
		return this.trigger("user_funds_transferred_out_of_bank", eventData);
	}
	
	public String userFundsTransferredOffRippleNetwork(String transactionId, String referenceUrl, String description, String userId, String amount) throws ClientException {
		Map<String, String> eventData = new HashMap<String, String>();
		eventData.put("transaction_id", transactionId);
		eventData.put("reference_url", referenceUrl);
		eventData.put("description", description);
		eventData.put("user_id", userId);
		eventData.put("amount", amount);
		
		return this.trigger("user_funds_transferred_off_ripple_network", eventData);
	}
	
	public String rippleWalletToBank(String transactionId, String referenceUrl, String description, String amount) throws ClientException {
		Map<String, String> eventData = new HashMap<String, String>();
		eventData.put("transaction_id", transactionId);
		eventData.put("reference_url", referenceUrl);
		eventData.put("description", description);
		eventData.put("amount", amount);
		
		return this.trigger("ripple_wallet_to_bank", eventData);
	}
	
}
