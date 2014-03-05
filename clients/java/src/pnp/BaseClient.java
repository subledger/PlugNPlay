package pnp;

import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Map;
import java.util.Scanner;

import pnp.org.json.JSONObject;
import pnp.utils.Base64;

public class BaseClient {
	
	private String host;
	
	private URL readUrl;	
	
	private URL triggerUrl;
	
	private String user;
	
	private String password;
	
	public BaseClient(String host, String user, String password) throws MalformedURLException {
		this.host = host;
		this.user = user;
		this.password = password;
		this.readUrl = new URL("http://" + this.host + "/api/1/event/read");
		this.triggerUrl = new URL("http://" + this.host + "/api/1/event/trigger");
	}
	
	public JSONObject read(String eventName, Map<String, Object> eventData) throws ClientException {
		return this.postEvent(this.readUrl, eventName, eventData);
	}	
	
	public JSONObject trigger(String eventName, Map<String, Object> eventData) throws ClientException {
		return this.postEvent(this.triggerUrl, eventName, eventData);
	}
	
	protected JSONObject postEvent(URL url, String eventName, Map<String, Object> eventData) throws ClientException {
        HttpURLConnection conn = null;
        
        try {
        	// get payload data
    		JSONObject data = new JSONObject();
    		data.put("name", eventName);
    		data.put("data", eventData);
            
            byte[] payload = data.toString().getBytes();
    		
            // open connection
            conn = (HttpURLConnection)url.openConnection();

            // set basic authentication credentials
            String authString = this.user + ":" + this.password;
            conn.setRequestProperty("Authorization", "Basic " + Base64.encodeBytes(authString.getBytes()));

            // set other connection attributes
            conn.setDoOutput(true);
            conn.setRequestMethod("POST");
            conn.setFixedLengthStreamingMode(payload.length);
            conn.setRequestProperty("Content-Type", "application/json");

            // write payload to output stream
            conn.getOutputStream().write(payload);
            
            // check response
            int status = conn.getResponseCode();
            
            if(status == HttpURLConnection.HTTP_OK) {
            	String response = readInputStream(conn.getInputStream());
            	return new JSONObject(response);

            } else {
            	throw new ClientException(status, conn.getResponseMessage());
            }
            
        } catch (Throwable ex) {
        	throw new ClientException(ex.getMessage(), ex);
 
        } finally {
            if (conn != null) {
            	conn.disconnect();
            }
        }		
	}	
	
    private static String readInputStream(InputStream is) throws IOException {
        Scanner s = null;
        StringBuilder response = new StringBuilder();
        
       
        try {
        	s = new Scanner(is, "UTF-8").useDelimiter("\\A");
        	
        	while(s.hasNext()) {
        		response.append(s.next());
        	}
        	
        } finally {
        	if (s != null) {
        		s.close();
        	}
        }
        
        return response.toString();
    }
}
