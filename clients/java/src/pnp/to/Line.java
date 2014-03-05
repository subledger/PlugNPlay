package pnp.to;

import java.io.Serializable;
import java.util.Date;

public class Line implements Serializable {
	private static final long serialVersionUID = 1L;
	
	private String id;
	
	private Long version;
	
	private String journalEntryId;
	
	private String accountId;	
	
	private Date postedAt;
	
	private Date effectiveAt;
	
	private Balance balance;
	
	private Value value;
	
	private String description;

	public Line(String id, Long version, String journalEntryId,
			String accountId, Date postedAt, Date effectiveAt, Balance balance,
			Value value, String description) {
		
		super();
		this.id = id;
		this.version = version;
		this.journalEntryId = journalEntryId;
		this.accountId = accountId;
		this.postedAt = postedAt;
		this.effectiveAt = effectiveAt;
		this.balance = balance;
		this.value = value;
		this.description = description;
	}
	
	public String toString() {
		return description + ": " + this.value.toString();
	}

	public static long getSerialversionuid() {
		return serialVersionUID;
	}

	public String getId() {
		return id;
	}

	public Long getVersion() {
		return version;
	}

	public String getJournalEntryId() {
		return journalEntryId;
	}

	public String getAccountId() {
		return accountId;
	}

	public Date getPostedAt() {
		return postedAt;
	}

	public Date getEffectiveAt() {
		return effectiveAt;
	}

	public Balance getBalance() {
		return balance;
	}

	public Value getValue() {
		return value;
	}

	public String getDescription() {
		return description;
	}

}
