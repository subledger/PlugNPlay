package pnp.to;

public enum Type {
	CREDIT, DEBIT, ZERO;
	
	public static Type fromString(String str) {
		if ("credit".equals(str)) {
			return CREDIT;
			
		} else if ("debit".equals(str)) {
			return DEBIT;
			
		} else if ("zero".equals(str)) {
			return ZERO;
		}
		
		return null;
	}
}
