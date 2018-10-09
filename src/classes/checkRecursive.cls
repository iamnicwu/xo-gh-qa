public Class checkRecursive{
	private static boolean run = true;
	private static integer i = 0;
	public static boolean runOnce(){
		if(run){
			run = false;
			return true;
		}else{
			return run;
		}
	}

	public static boolean runTwice(){
		i++;
		if( i == 2){
			run = false;
			return true;
		}else{
			return run;
		}
	}
}