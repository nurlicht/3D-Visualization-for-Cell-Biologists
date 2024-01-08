// Program: 3DRender.ijm
// Version: 1
// Programming language: ImageJ Macro
// Description: Performs volumetric 3D rendering on a z-stack using orthogonal projections, only (no perspective, shading, transparency ...). It is not intended to bypass the powerful 3D Viewer of ImageJ, rather 1) to get better insight into the 3D Viewer, 2) to note the "semi-quantitative" nature of 3D visualization, and 3) to have a quantitative basis for understanding OpenGL (3D Viewer) results. The core of this macro is performing 3D rotations of a z-stack using TransformJ. 

// Programmer: Aliakbar Jafarpour
// Affiliation: Center for Molecular Biology at University of Heidelberg (ZMBH)
// Email: jafarpour.a.j@ieee.org

macro "Main" {
	Initialize();
	renderingParams = getRenderingParams();
	inputImageTitle = loadImage(renderingParams);
	if (inputImageTitle != false) {
		zeroPaddedImageTitle = padZeros(inputImageTitle, renderingParams);
		renderedImageTitle = getRotationProjections(zeroPaddedImageTitle, renderingParams);
		geometricalXRayScattering(renderedImageTitle, renderingParams);
		makeImagesVisible();
	}
}

function geometricalXRayScattering(currentImageTitle, renderingParams) {
	crystallographyFlag = renderingParams[3];
	if (crystallographyFlag) {
		nImages_ = nImages + 1;
		nSlices_ = nSlices;
		imWidth = getWidth;
		imHeight = getHeight;
		
		baseName = "(Geometrical) X-Ray Scattering";
		tempTitle = "Slice_Copy";
		run("8-bit");
		selectWindow(currentImageTitle);
		wait(1);
		for (cntr = 0; cntr < nSlices_; cntr++) {
			setSlice(1 + cntr);

			run("Duplicate...", "title=" + tempTitle);			
			while (!isOpen(tempTitle)) {
			}
			selectWindow(tempTitle);
			run("Canvas Size...", "width=" + (2 * imWidth) + " height=" + (2 * imHeight) + " position=Center zero");
			while(imWidth == getWidth) {
			}

			run("FFT Options...", "fft do");
			while (nImages == nImages_) {
			}
			ftTitle = baseName + ", slice " + (cntr + 1);
			rename(ftTitle);
			while (!isOpen(ftTitle)) {
			}
			run("Canvas Size...", "width=" + (1 * imWidth) + " height=" + (1 * imHeight) + " position=Center zero");
			while(imWidth != getWidth) {
			}
			//run("8-bit");wait(1);

			run("Concatenate...", "  title=[" + currentImageTitle + "] image1=[" + currentImageTitle + "] image2=[" +  ftTitle + "] image3=[-- None --]");	

			close(tempTitle);
			while (isOpen(tempTitle)) {
			}

			showProgress(cntr, nSlices_);
		}
		run("Stack to Hyperstack...", "order=xyczt(default) channels=1 slices=" + nSlices_ + " frames=2 display=Color");
	}
}

function getRotationProjections(zeroPaddedImageTitle, renderingParams) {
	renderedImageTitle = "Rendered_Image";
	projectionType = renderingParams[0];
	if (projectionType != "Median") {
		projectionType = "[" + projectionType + "]";
	}
	rotationAngle = renderingParams[1];
	nAngles = floor(360 / rotationAngle);
	selectWindow(zeroPaddedImageTitle);
	projectedImageTitle = newArray(nAngles);
	showStatus("Rotataing at " + nAngles + " angles ...");
	for (aCntr = 0; aCntr < nAngles; aCntr++) {
		currentAngle = rotationAngle * aCntr;
		rotatedImageTitle = "Angle_" + currentAngle;
		projectedImageTitle[aCntr] = "Projection_" + rotatedImageTitle;
		selectWindow(zeroPaddedImageTitle);
		wait(10);
		run("TransformJ Rotate", "z-angle=0.0 y-angle=" + currentAngle + " x-angle=0.0 interpolation=Linear background=0.0");
		while(nImages == (1 + aCntr)) {
		}
		wait(10);
		rename(rotatedImageTitle);
		wait(1);
		while(!isOpen(rotatedImageTitle)) {
		}
		wait(10);
		run("Z Project...", "projection=" + projectionType);
		while(nImages == (2 + aCntr)) {
		}
		wait(1);
		rename(projectedImageTitle[aCntr]);
		while(!isOpen(projectedImageTitle[aCntr])) {
		}
		wait(1);
		showProgress(aCntr, nAngles);
	}
	closeImage(zeroPaddedImageTitle);
	closeImage(rotatedImageTitle);
	run("Images to Stack", "name=" + renderedImageTitle + " title=[] use");
	while(!isOpen(renderedImageTitle)) {
	}
	wait(1);
	nImages_ = nImages;
	imagesList = getList("image.titles");
	for (cntr = 0; cntr < nImages_; cntr++) {
		currentTitle = imagesList[cntr];
		if (currentTitle != renderedImageTitle) {
			closeImage(currentTitle);
		}
	}
	return renderedImageTitle;
}

function makeImagesVisible() {
  	setBatchMode("exit and display");
  	setBatchMode(false);
  	wait(1);
	
}

function Initialize() {
	print("\\Clear");

  	setBatchMode("exit and display");
  	wait(100);
	if (nImages > 0) {
		run("Close All");
		while (nImages > 0) {
		}
		wait(1);
	}
  	setBatchMode(true);
  	wait(10);

	if (nResults > 0) {
		run("Clear Results");
	}
	if (isOpen("Results")) {
		selectWindow("Results");
		run("Close");
	}
	wait(1);

  	setBatchMode(true);
  	wait(100);

}

function closeImage(imageTitle) {
	close(imageTitle);
	while (isOpen(imageTitle)) {
	}
	wait(1);
}

function getRenderingParams() {
	projectionVector = newArray("Max Intensity", "Average Intensity", "Standard Deviation", "Sum Slices", "Median");
	projectionType = projectionVector[0];
	rotationAngle = 15;
	demoImageFlag = true;
	crystallographyFlag = false;
	padZeroFlag = true;
	nRenderingParams = 5;
	Dialog.create("Rendering Parameters");
	Dialog.addRadioButtonGroup("Projection Type", projectionVector, lengthOf(projectionVector), 1, projectionType);
	Dialog.addNumber("Rotation Angle (in degrees)", rotationAngle);
	Dialog.addCheckbox("Use a demo image", demoImageFlag);
	Dialog.addCheckbox("Simulate X-ray crystallography", crystallographyFlag);
	Dialog.addCheckbox("Make enough room (in X-Y-Z) for rotations", padZeroFlag);
	Dialog.show();
	renderingParams = newArray(nRenderingParams);
	renderingParams[0] = Dialog.getRadioButton();
	renderingParams[1] = parseFloat(Dialog.getNumber());
	renderingParams[2] = Dialog.getCheckbox();
	renderingParams[3] = Dialog.getCheckbox();
	renderingParams[4] = Dialog.getCheckbox();
	if (renderingParams[3]) {
		if (renderingParams[0] != projectionVector[3]) {
			renderingParams[0] = projectionVector[3];
			showMessage("<html>Projection type was set to <b>Sum Slices</b>");
		}
	}
	return renderingParams;
}

function loadImage(renderingParams) {
	demoImageFlag = renderingParams[2];
	inputImageTitle = "originalImage";
	isStackFlag = true;
	if (demoImageFlag) {
		run("Fly Brain (1MB)");
	} else {
		open(File.openDialog("Please select the (single-channel and single-frame) Z-stack"));
		while (nImages == 0) {
		}
		wait(1);
		rename(inputImageTitle);
		while(!isOpen(inputImageTitle)) {
		}
		wait(1);
		Stack.getDimensions(imageWidth, imageHeight, nChannels_, nSlices_, nFrames_);
		if (nSlices_ == 1) {
			if (nFrames_ > 1) {
				nSlices_ = nFrames_;
				nFrames_ = 1; 
				Stack.setDimensions(nChannels_, nSlices_, nFrames_);
				wait(1);
				showMessage("" + nSlices_ + " frames are treadted as Z slices.");
				wait(1);
			} else {
				isStackFlag = false;
			}
		}
		isStackFlag = isStackFlag && (nChannels_ == 1);
	}
	if (isStackFlag) {
		run("8-bit");
		wait(1);
		rename(inputImageTitle);
		while(!isOpen(inputImageTitle)) {
		}
		wait(1);
	} else {
		showMessage("A Z-stack with a single frame and single channel is needed.");
		wait(1);
		inputImageTitle = false;
	}
	return inputImageTitle;
}

function padZeros(inputImageTitle, renderingParams) {
	padZeroFlag = renderingParams[4];
	if (padZeroFlag) {
		Stack.getDimensions(imageWidth, imageHeight, nChannels_, nSlices_, nFrames_);
	dMax = sqrt(pow(imageWidth, 2) + pow(imageHeight, 2) + pow(nSlices_, 2)) + 2;
		run("Canvas Size...", "width=" + dMax + " height=" + dMax + " position=Center zero");
		nSlices__ = dMax;
		Stack.getDimensions(imageWidth, imageHeight, nChannels_, nSlices_, nFrames_);
	
		bitDepth_ = bitDepth();
		if (bitDepth_ == 8) {
			imageType_ = "8-bit";
		} else if (bitDepth_ == 16) {
			imageType_ = "16-bit";
		} else if (bitDepth_ == 24) {
			imageType_ = "RGB";
		} else if (bitDepth_ == 32) {
			imageType_ = "32-bit";
		}
		imageType = imageType_ + " black";
	
		zSides = dMax - nSlices_;
		nHyperstacks = - floor(- zSides / nSlices_);
		nHyperstackSide = - floor(- nHyperstacks / 2);
		nExtraSlices = (2 * nHyperstackSide + 1) * nSlices_ - dMax;
		nExtraSlicesLeft = floor(nExtraSlices / 2);
		nExtraSlicesRight = nExtraSlices - nExtraSlicesLeft;
	
		//run("Add Slice");
	
		//Left zeros along Z
		for (cntr = 0; cntr < nHyperstackSide; cntr++) {
			zeroHyperStackTitle = "zeroHyperStack";
			if (cntr == 0) {
				currentImageTitle = inputImageTitle;
			} else {
				currentImageTitle = newImageTitle;
			}
			newImageTitle = inputImageTitle + "_left_" + toString(1 + cntr);
			run("New HyperStack...", "title=" + zeroHyperStackTitle + " type=" + imageType + " width=" + imageWidth + " height=" + imageHeight + " channels=" + nChannels_ + " slices=" + nSlices_ + " frames=" + nFrames_ + " ");		
			while(!isOpen(zeroHyperStackTitle)) {
			}
			wait(1);
			run("Concatenate...", "  title=[" + newImageTitle + "] image1=[" + zeroHyperStackTitle + "] image2=[" + currentImageTitle + "]");
			while(!isOpen(newImageTitle)) {
			}
			wait(1);
		}
		
		//Right zeros along Z
		for (cntr = 0; cntr < nHyperstackSide; cntr++) {
			zeroHyperStackTitle = "zeroHyperStack";
			currentImageTitle = newImageTitle;
			newImageTitle = inputImageTitle + "_right_" + toString(1 + cntr);
			run("New HyperStack...", "title=" + zeroHyperStackTitle + " type=" + imageType + " width=" + imageWidth + " height=" + imageHeight + " channels=" + nChannels_ + " slices=" + nSlices_ + " frames=" + nFrames_ + " ");		
			while(!isOpen(zeroHyperStackTitle)) {
			}
			wait(1);
			run("Concatenate...", "  title=[" + newImageTitle + "] image1=[" + currentImageTitle + "] image2=[" + zeroHyperStackTitle + "]");
			while(!isOpen(newImageTitle)) {
			}
			wait(1);
		}
		
		// Cut extra slices on the sides
		zeroPaddedImageTitle = "3D_Enlarged";
		if (nExtraSlices > 1) {
			run("Duplicate...", "title=" + zeroPaddedImageTitle + " duplicate range=" + (nExtraSlicesLeft + 1) + "-" + (nExtraSlicesLeft + dMax));
			closeImage(newImageTitle);
			selectWindow(zeroPaddedImageTitle);
		} else {
			selectWindow(newImageTitle);
			rename(zeroPaddedImageTitle);
			while(isOpen(zeroPaddedImageTitle)) {
			}
			wait(1);
		}
		run("8-bit");
		wait(1);
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0");
	} else {
		zeroPaddedImageTitle = inputImageTitle;
	}
	return zeroPaddedImageTitle;
}

