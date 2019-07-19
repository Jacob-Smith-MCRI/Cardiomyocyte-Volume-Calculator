macro "IMS Stack to Tiff Action Tool - B04C000T0406IT3406MT9406S"{
	
	/* Version 1.0 - July 18, 2019
	 * Created by Jacob Smith at the Murdoch Children's
	 * Research Institute, Cardiac Regeneration Laboratory
	 * 
	 *This macro converts .ims z stacks into usable .tif images
	 *
	 */

	//Define variables and select the .ims folder location and .tif output save location
	tifName = newArray();
	setOption("ExpandableArrays", true);
	imsLocation = getDirectory("Choose a Directory");
	imsList = getFileList(imsLocation);
	saveLocation = getDirectory("Choose a Directory to save");

	//Loop through all files in the selected folder and save them as .tif images.
	for (i = 0; i < imsList.length; i++) {
		//Only select images that end with ".ims"
		if (endsWith(imsList[i], ".ims") == true){
			run("Bio-Formats", "open=["+imsLocation+imsList[i]+ "] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_1");
			tifName = substring(imsList[i], 0, lastIndexOf(imsList[i], ".ims"));
			saveAs("tif", saveLocation + tifName + ".tif");
			close();
		}
	}
}