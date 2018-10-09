global with sharing class IFrameService {
	
	webservice static String generateIFrame(String pageURL, String height, String width, Boolean animate) {
		String iframeHtml = '<div class="iframe-container">'
												+	'<div class="{ANIMATE}">'
													+	'<div class="tab-container">'
														+	'<span class="close-button" onclick="closeIframe(this, ' + animate + ');">&#10005;</span>'
													+	'</div>'
													+	'<iframe class="xo-iframe" src="' + pageURL + '" height="' +  height + '" width="' + width + '" />'
												+	'</div>'
											+	'</div>';

		iframeHtml = iframeHtml.replace('{ANIMATE}', animate ? 'animated fadeInDown' : '');

		IFrame iframeWrapper = new IFrame(iframeHtml);

		iframeWrapper.cssResources.add('/resource/iframecss');
		if(animate) {
			iframeWrapper.cssResources.add('/resource/animate');
		}
		
		// Added to javascript button
		//iframeWrapper.jsLibraries.add('/resource/1459960305000/iframejs');

		// IFrame class will not return as webservice - returns empty string. JSON serialize and parse on the other side.
		//return iframeWrapper;
		return JSON.serialize(iframeWrapper);
	}

	global with sharing class IFrame {
		String iFrameHTML;
		List<String> jsLibraries;
		List<String> cssResources;

		global IFrame() {
			iFrameHTML = '';
			jsLibraries = new List<String>();
			cssResources = new List<String>();
		}

		global IFrame(String htmlCode) {
			iFrameHTML = htmlCode;
			jsLibraries = new List<String>();
			cssResources = new List<String>();
		}
	}
}