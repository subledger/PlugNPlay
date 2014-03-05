package pnp.utils;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;

import pnp.ClientException;

public class DateUtils {

	public static Date parseISO8601Date(String iso8601string) throws ClientException {
		String s = iso8601string.replace("Z", "+00:00");
		
		try {
			// to get rid of the ":"
			s = s.substring(0, 22) + s.substring(23);
			
			return new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ").parse(s);
			
		} catch (IndexOutOfBoundsException e) {
			throw new ClientException("Error parsing iso8601 date, invalid length", e);
			
		} catch (ParseException e) {
			throw new ClientException(e.getMessage(), e);
		}
	}
	
    public static String dateToIso8601String(final Date date) {
    	String formatted = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ").format(date);
    	return formatted.substring(0, 22) + ":" + formatted.substring(22);
    }

}
