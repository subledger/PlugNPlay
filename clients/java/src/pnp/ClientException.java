package pnp;

public class ClientException extends Exception {

	private static final long serialVersionUID = 1L;
	
	private Integer httpCode;

	public ClientException() {
	}

	public ClientException(String message) {
		super(message);
	}
	
	public ClientException(Integer httpCode, String message) {
		super("HttpCode: " + httpCode + ", Message: " + message);
	}
	
	public ClientException(Throwable cause) {
		super(cause);
	}

	public ClientException(String message, Throwable cause) {
		super(message, cause);
	}
	
	public ClientException(Integer httpCode, String message, Throwable cause) {
		super("HttpCode: " + httpCode + ", Message: " + message, cause);
	}

	public Integer getHttpCode() {
		return this.httpCode;
	}

}
