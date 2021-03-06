//Generated by wsdl2apex

public class faultApiZuoraCom {
    public class ApiFault {
        public String FaultCode;
        public String FaultMessage;
        private String[] FaultCode_type_info = new String[]{'FaultCode','http://fault.api.zuora.com/',null,'0','1','true'};
        private String[] FaultMessage_type_info = new String[]{'FaultMessage','http://fault.api.zuora.com/',null,'0','1','true'};
        private String[] apex_schema_type_info = new String[]{'http://fault.api.zuora.com/','true','true'};
        private String[] field_order_type_info = new String[]{'FaultCode','FaultMessage'};
    }
    public class MalformedQueryFault {
        private String[] apex_schema_type_info = new String[]{'http://fault.api.zuora.com/','true','true'};
        private String[] field_order_type_info = new String[]{};
    }
    public class InvalidValueFault {
        private String[] apex_schema_type_info = new String[]{'http://fault.api.zuora.com/','true','true'};
        private String[] field_order_type_info = new String[]{};
    }
    public class UnexpectedErrorFault {
        private String[] apex_schema_type_info = new String[]{'http://fault.api.zuora.com/','true','true'};
        private String[] field_order_type_info = new String[]{};
    }
    public class InvalidQueryLocatorFault {
        private String[] apex_schema_type_info = new String[]{'http://fault.api.zuora.com/','true','true'};
        private String[] field_order_type_info = new String[]{};
    }
    public class InvalidTypeFault {
        private String[] apex_schema_type_info = new String[]{'http://fault.api.zuora.com/','true','true'};
        private String[] field_order_type_info = new String[]{};
    }
    public class LoginFault {
        private String[] apex_schema_type_info = new String[]{'http://fault.api.zuora.com/','true','true'};
        private String[] field_order_type_info = new String[]{};
    }
}