package pnp.to;

import java.io.Serializable;

public class Balance implements Serializable {
	private static final long serialVersionUID = 1L;

	private Value creditValue;
	
	private Value debitValue;
	
	private Value value;

	public Balance(Value creditValue, Value debitValue, Value value) {
		this.creditValue = creditValue;
		this.debitValue = debitValue;
		this.value = value;
	}
	
	public String toString() {
		return this.value.toString();
	}

	public Value getCreditValue() {
		return creditValue;
	}

	public Value getDebitValue() {
		return debitValue;
	}

	public Value getValue() {
		return value;
	}

}
