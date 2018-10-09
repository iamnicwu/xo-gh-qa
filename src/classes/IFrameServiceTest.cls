@isTest
private class IFrameServiceTest {
	
	@isTest static void testGenerateIFrame() {
		IFrameService.generateIFrame('https://www.testing.com', '100px', '98%', true);
		IFrameService.generateIFrame('https://www.testing.com', '100px', '98%', false);

		new IFrameService.IFrame();
	}
}