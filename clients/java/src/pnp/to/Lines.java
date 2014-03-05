package pnp.to;

import java.util.List;

public class Lines {
	
	private List<Line> lines;
	
	private Integer pageSize;
	
	private String pageId;
	
	public Lines(List<Line> lines, Integer pageSize) {
		this.lines = lines;
		this.pageSize = pageSize;
		
		if (this.lines.size() > 0) {
			this.pageId = this.lines.iterator().next().getId();
		}
	}
	
	public String getPageId() {
		return pageId;
	}
	
	public List<Line> getLines() {
		return lines;
	}

	public boolean hasNext() {
		return lines.size() > 0 && lines.size() == pageSize;
	}

	public String getNextPageId() {
		if (this.hasNext()) {
			return lines.get(lines.size() - 1).getId();
		}
		
		return null;
	}
	
}
