/* ============================================================
 * This code is part of the "apex-lang" open source project avaiable at:
 * 
 *      http://code.google.com/p/apex-lang/
 *
 * This code is licensed under the Apache License, Version 2.0.  You may obtain a 
 * copy of the License at:
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * ============================================================
 */
/**
 * Port of the StringUtils class from Java to Apex.  This
 * class is part of the Apache Commons Lang project available
 * at http://commons.apache.org/lang/.
 */
global class StringUtils {

    global static final String EMPTY = '';
    global static final String LF = '\n';
    global static final String CR = '\r';
    global static final Integer INDEX_NOT_FOUND = -1;

    private static final Integer PAD_LIMIT = 8192;

    global static String charAt(String str, Integer index) {
        if(str == null){
            return null;
        }
        if(str.length() <= 0){
            return str;    
        }
        if(index < 0 || index >= str.length()){
            return null;    
        }
        return str.substring(index, index+1);
    }
    

}