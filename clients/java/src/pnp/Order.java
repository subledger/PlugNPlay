package pnp;

public enum Order {
	ASC, DESC;
	
	public String toString() {
		return name().toLowerCase();
	}
}
