package pnp;

import java.math.BigDecimal;
import java.net.MalformedURLException;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import pnp.org.json.JSONArray;
import pnp.org.json.JSONObject;
import pnp.to.Balance;
import pnp.to.Line;
import pnp.to.Lines;
import pnp.to.Type;
import pnp.to.Value;
import pnp.utils.DateUtils;

public class Client extends BaseClient {
	
	public Client(String host, String user, String password) throws MalformedURLException {
		super(host, user, password);
	}
	
	public Balance getUserBalance(String userId, Date at) throws ClientException {
		// prepare event data
		Map<String, Object> eventData = new HashMap<String, Object>();
		
		// set user id
		eventData.put("user_id", userId);
		
		// set account type as account_payable
		List<String> sufixes = new ArrayList<String>();
		sufixes.add("accounts_payable");
		
		eventData.put("sufixes", sufixes);
		
		// set pagination data
		eventData.put("at", DateUtils.dateToIso8601String(at));
		
		// call the event
		JSONObject jsonResponse = this.read("user_balance", eventData);
		return jsonBalanceToBalance(jsonResponse, "response");
	}
	
	public Lines getUserTransactionHistory(String userId, Date date, String pageId, Integer perPage, Order order) throws ClientException {
		// prepare event data
		Map<String, Object> eventData = new HashMap<String, Object>();
		
		// set user id
		eventData.put("user_id", userId);
		
		// set account type as account_payable
		List<String> sufixes = new ArrayList<String>();
		sufixes.add("accounts_payable");
		
		eventData.put("sufixes", sufixes);
		
		// set pagination data
		eventData.put("date", DateUtils.dateToIso8601String(date));
		eventData.put("per_page", perPage);
		eventData.put("page_id", pageId);
		eventData.put("order", order.toString());
		
		// call the event
		JSONObject jsonResponse = this.read("user_history", eventData);
		
		// read the response 
		JSONArray jsonLines = jsonResponse.getJSONArray("response");
		
		// convert the json to Lines
		List<Line> lines = new ArrayList<Line>(jsonLines.length());
		
		for(int i=0; i<jsonLines.length(); i++) {
			JSONObject jsonLine = jsonLines.getJSONObject(i);
			
			lines.add(
				new Line(
					jsonLine.getString("id"),
					jsonLine.getLong("version"),
					jsonLine.getString("journal_entry"),
					jsonLine.getString("account"),
					jsonDateToDate(jsonLine, "posted_at"),
					jsonDateToDate(jsonLine, "effective_at"),
					jsonBalanceToBalance(jsonLine, "balance"),
					jsonValueToValue(jsonLine, "value"),
					jsonLine.getString("description")
				)
			);
		}
		
		return new Lines(lines, perPage);
	}
	
	public String userFundsReceived(String transactionId, String referenceUrl, String description, String userId, String depositAmount, String userFunds, String gatewayFee) throws ClientException {
		Map<String, Object> eventData = new HashMap<String, Object>();
		eventData.put("transaction_id", transactionId);
		eventData.put("reference_url", referenceUrl);
		eventData.put("description", description);
		eventData.put("user_id", userId);
		eventData.put("deposit_amount", depositAmount);
		eventData.put("user_funds", userFunds);
		eventData.put("gateway_fee", gatewayFee);
		
		return this.trigger("user_funds_received", eventData).toString();
	}
	
	public String userRippleWalletFunded(String transactionId, String referenceUrl, String description, String userId, String amount) throws ClientException {
		Map<String, Object> eventData = new HashMap<String, Object>();
		eventData.put("transaction_id", transactionId);
		eventData.put("reference_url", referenceUrl);
		eventData.put("description", description);
		eventData.put("user_id", userId);
		eventData.put("amount", amount);
		
		return this.trigger("user_ripple_wallet_funded", eventData).toString();
	}
	
	public String bankToRippleWallet(String transactionId, String referenceUrl, String description, String amount) throws ClientException {
		Map<String, Object> eventData = new HashMap<String, Object>();
		eventData.put("transaction_id", transactionId);
		eventData.put("reference_url", referenceUrl);
		eventData.put("description", description);
		eventData.put("amount", amount);
		
		return this.trigger("bank_to_ripple_wallet", eventData).toString();
	}
	
	public String userFundsTransferredOutOfBank(String transactionId, String referenceUrl, String description, String userId, String totalAmount, String transferAmount, String gatewayFee) throws ClientException {
		Map<String, Object> eventData = new HashMap<String, Object>();
		eventData.put("transaction_id", transactionId);
		eventData.put("reference_url", referenceUrl);
		eventData.put("description", description);
		eventData.put("user_id", userId);
		eventData.put("total_amount", totalAmount);
		eventData.put("transfer_amount", transferAmount);
		eventData.put("gateway_fee", gatewayFee);
		
		return this.trigger("user_funds_transferred_out_of_bank", eventData).toString();
	}
	
	public String userFundsTransferredOffRippleNetwork(String transactionId, String referenceUrl, String description, String userId, String amount) throws ClientException {
		Map<String, Object> eventData = new HashMap<String, Object>();
		eventData.put("transaction_id", transactionId);
		eventData.put("reference_url", referenceUrl);
		eventData.put("description", description);
		eventData.put("user_id", userId);
		eventData.put("amount", amount);
		
		return this.trigger("user_funds_transferred_off_ripple_network", eventData).toString();
	}
	
	public String rippleWalletToBank(String transactionId, String referenceUrl, String description, String amount) throws ClientException {
		Map<String, Object> eventData = new HashMap<String, Object>();
		eventData.put("transaction_id", transactionId);
		eventData.put("reference_url", referenceUrl);
		eventData.put("description", description);
		eventData.put("amount", amount);
		
		return this.trigger("ripple_wallet_to_bank", eventData).toString();
	}
	
	/*** Utils ***/
	protected Type jsonTypeToType(JSONObject json, String key) {
		return Type.fromString(json.getString(key));
	}
	
	protected BigDecimal jsonAmountToAmount(JSONObject json, String key) {
		return new BigDecimal(json.getString(key));
	}
	
	protected Date jsonDateToDate(JSONObject json, String key) throws ClientException {
		return DateUtils.parseISO8601Date(json.getString(key));
	}
	
	protected Value jsonValueToValue(JSONObject json, String key) {
		JSONObject jsonValue = json.getJSONObject(key);
		
		return new Value(
			jsonTypeToType(jsonValue, "type"),
			jsonAmountToAmount(jsonValue, "amount")
		);		
	}
	
	protected Balance jsonBalanceToBalance(JSONObject json, String key) {
		JSONObject jsonBalance = json.getJSONObject(key);
		
		Value balanceCreditValue = jsonValueToValue(jsonBalance, "credit_value");
		Value balanceDebitValue  = jsonValueToValue(jsonBalance, "credit_value");
		Value balanceValue       = jsonValueToValue(jsonBalance, "value");
		
		return new Balance(balanceCreditValue, balanceDebitValue, balanceValue);		
	}
	
}
