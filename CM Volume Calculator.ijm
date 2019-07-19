macro "Cardiomyocyte Volume Calculator Action Tool - B04C000T0408CT8408V"{

	/* Version 1.0 - July 18, 2019
	 * Created by Jacob Smith at the Murdoch Children's
	 * Research Institute, Cardiac Regeneration Laboratory
	 * 
	 * This macro uses the WEKA Trainable Segementation plugin to 
	 * first detect the Cardiomyocyte regions of each slice of .tif stack,
	 * then finds each region's area. The area of each region is multiplied
	 * by the slice thickness and added together to find the volume.
	 * 
	 * This macro accepts folders containing multiple images (each as a
	 * signle cell) and outputs a .cvs spreadsheet file containing the
	 * calculated volume of each Cardiomyocyte.
	 * 
	 */

	//Enable dynamic, expandable arrays
	setOption("ExpandableArrays", true);
	
	//Only versions of ImageJ above 1.52o support deleting elements from arrays
	requires("1.52o");
	
	//Select the directory containing the tif stacks - must contain ONLY tifs
	folderLocation = getDirectory("Choose a Directory");
	imageList = getFileList(folderLocation);
	
	savePath = getDirectory("Choose a Directory to save");
	
	//Allow the user to specify the thickness of each slice in the z stack
	//The default slice number is 1.2um
	Dialog.create("Enter a number");
	Dialog.addNumber("Slice size:", 1.2);
	Dialog.show();
	sliceSize = Dialog.getNumber();
	
	//Ask the user for the WEKA Classifier file, created by the WEKA Trainable Segmentation plugin
	classifier = File.openDialog("Please select the classifier");
	
	//Generate the arrays for storing the names and volumes of each file
	nameArray = newArray();
	volArray = newArray();
	
	//Loop through each file in the folder
	for (imageCounter = 0; imageCounter < imageList.length; imageCounter++){
		
		//Open a .tif z stack, and seperate and save the filename
		open(folderLocation+imageList[imageCounter]);
		
		fileName = getInfo("image.filename");
		name = split(fileName, ".tif");

		//Grab the dimensions of the image, and generate some variables
		x = getWidth();
		y = getHeight();
		z = nSlices();
		
		roiSliceArea = 0;
		sliceVol = 0;
		sliceArea = newArray();
		
	
		
		// start plugin
		run("Trainable Weka Segmentation");
		 
		// wait for the plugin to load
		wait(3000);
		selectWindow("Trainable Weka Segmentation v3.2.33");
		
		//Load the classifier as specified above 
		call("trainableSegmentation.Weka_Segmentation.loadClassifier", classifier);
		
		// change class names
		call("trainableSegmentation.Weka_Segmentation.changeClassName", "0", "Cardiomyocyte");
		call("trainableSegmentation.Weka_Segmentation.changeClassName", "1", "Background");
		 
		// display probability maps
		call("trainableSegmentation.Weka_Segmentation.getProbability");
		call("trainableSegmentation.Weka_Segmentation.getResult");
		
		selectWindow("Probability maps");
		saveAs("tif", savePath+"probability.tif");
		
		//Split the channels since the probability map displays both 
		run("Next Slice [>]");
		run("Delete Slice", "delete=channel");
	
		//Wait 1000ms for splitting channels to finish loading
		wait(1000);
		
		//Threshold the image and convert it to a binary image
		setAutoThreshold("Default dark");
		//run("Threshold...");
		//Only areas with above 0.2 are considered to be part of the cell
		setThreshold(0.2000, 1000000000000000000000000000000.0000);
		run("NaN Background", "stack");
		run("Make Binary", "method=Default background=Dark");
	
	
		//Reports how many slices are in the image and how many will be processed
		print("There are "+z+" slices");
	
		//Loop through each slice in the stack for the image
		for (i = 0; i < z; i++){ 
			//Resets the total slice area
			roiSliceArea = 0;
			setBatchMode(true);
			//Converts the thresholded image into measurable Regions of interest (ROIs) 
			//Removed small background particles below 50 um
			run("Set Measurements...", "area mean perimeter bounding shape feret's integrated display decimal=3");
			run("Analyze Particles...", "size=50-infinity circularity=0.00-1.0 show=Masks");
			saveAs("tif", savePath+"probability"+"mask1.tif");
			run("Set Measurements...", "area mean perimeter bounding shape feret's integrated display redirect=None decimal=3"); //redirect=[fileName] 
			run("Analyze Particles...", "size=50-Infinity show=Outlines display clear add");
			saveAs("tif", savePath+"probability"+"mask2_"+i+".tif");
			close("probability"+"mask1.tif");
			run("Clear Results");
	
			//Loop through each ROI in the slice, and calculate the area of each
			for (l = 0; l < roiManager("count"); l++){ 
				selectImage("probabilitymask2_"+i+".tif");
				roiManager("select", l);
				roiManager("measure");
				selectWindow("Results");
				roiSliceArea = roiSliceArea + getResult("Area");
				
				//Uncomment below to get info about the area of each ROI in each slice (debugging) 
				//print("Slice "+i+" roi: "+l+" area is "+getResult("Area"));
			}
		
			//Adds the total slice area to the slice area array for the rest of the sample
			sliceArea[i] = roiSliceArea;
			close("probability"+"mask2_"+i+".tif");
			
			//Moves to the next slice of the the z stack image
			selectImage("probability.tif");
			run("Next Slice [>]");
		}
		//Uncomment to save the ROI to investigate the quality of segmentation
		roiManager("save", savePath+"rois.zip");
		
		close("ROI Manager");
		setBatchMode(false);
		close("probability.tif");
		close("Trainable Weka Segmentation v3.2.33");
		
		//Display the slice area array which shows the individual area of each slice
		print("The area of each slice is ");
		Array.print(sliceArea);
	
		//Calculate the total volume
		for (j = 0; j < z; j++){
			sliceVol = sliceVol + sliceSize*sliceArea[j];
		}
	
		//Print and save the volume for that particular sample to the volume array for later use
		print("The cell volume is "+sliceVol+"um3");
		
		nameArray[imageCounter] = fileName;
		volArray[imageCounter] = sliceVol;
	
		//Display the volumes for the previous samples
		print("The stored names are: ");
		Array.print(nameArray);
		print("The stored volumes are: ");
		Array.print(volArray);
		
		//Reset the sliceArea array by deleting the area of each slice. Needed to processes the next sample. Requires version 1.52o
		sliceReset = sliceArea.length - 1;
		while (sliceArea.length != 0){ 
			sliceArea = Array.deleteIndex(sliceArea, sliceReset);
			sliceReset = sliceReset - 1;
		}
	}
	
	//Display and save the volumes to a spreadsheet
	print("The volumes of each sample are displayed now");
	Array.show(nameArray, volArray);
	saveAs("Results", savePath + "Cardiomyocyte volume.csv");

}