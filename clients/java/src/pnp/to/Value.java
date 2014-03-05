package pnp.to;

import java.io.Serializable;
import java.math.BigDecimal;

public class Value implements Serializable {
	private static final long serialVersionUID = 1L;

	private BigDecimal amount;
	
	private Type type;

	public Value(Type type, BigDecimal amount) {
		this.type = type;
		this.amount = amount;
	}
	
	public String toString() {
		return this.amount + " (" + this.type + ")";
	}

	public BigDecimal getAmount() {
		return amount;
	}

	public Type getType() {
		return type;
	}
	
}
