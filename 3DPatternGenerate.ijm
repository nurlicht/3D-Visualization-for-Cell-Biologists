// Program: 3DpatternGenerate.ijm
// Version: 1
// Programming language: ImageJ Macro
// Description: Generates curves (1D), surfaces (2D), and volumetric data (3D) in 3D space. Some of the 3D objects have been explicitly associated with biological examples (helicoidal membrane motifs, molecular knots, and Photo 51).   

// Programmer: Aliakbar Jafarpour
// Affiliation: Center for Molecular Biology at University of Heidelberg (ZMBH)
// Email: jafarpour.a.j@ieee.org

macro "Main" {
	Initialize();
	objectParameters = getObjectDimensions();
	objectData = getObjectVoxels(objectParameters);
	imageTitle = createStack(objectParameters);
	displayObject(objectData, objectParameters, imageTitle);
	objectData = trimObject(objectData, objectParameters, imageTitle);
	makeImagesVisible();
	displayBiologicalRelevance(objectParameters, imageTitle);
}

function makeImagesVisible() {
  	setBatchMode("exit and display");
  	setBatchMode(false);
  	wait(1);
	
}

function displayBiologicalRelevance(objectParameters, imageTitle) {
	objectType = toLowerCase(objectParameters[0]);
  	if (objectType == "helicoid") {
		url1 = "";
		url2 = "http://www.imls.uzh.ch/research/klemm/publ/Cover_cell.jpg";
		showMessage("<html>Link to biological example: <a href=\"" + url1 + "\" target=\"_blank\">Publication</a>");
		wait(1);
		open(url2);
		wait(1);
  	} else if (objectType == "trefoil knot") {
		url1 = "http://www.nature.com/nchembio/journal/v8/n2/full/nchembio.742.html";
		url2 = "http://www.nature.com/nchembio/journal/v8/n2/images/nchembio.742-F1.jpg";
		showMessage("<html>Link to biological example: <a href=\"" + url1 + "\" target=\"_blank\">Molecular knot</a>");
		wait(1);
		open(url2);
		wait(1);
  	} else if (objectType == "double helix") {
		generatePhoto51(imageTitle);
		url1 = "http://www.pbs.org/wgbh/nova/photo51/";
		url2 = "http://www-tc.pbs.org/wgbh/nova/photo51/images/photo51-home.jpg";
		showMessage("<html>Link to biological example: <a href=\"" + url1 + "\" target=\"_blank\">Photo 51</a>");
		wait(1);
		open(url2);
		wait(1);
  	}
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

function trimObject(objectData, objectParameters, imageTitle) {
	objectType = toLowerCase(objectParameters[0]);
	nX = objectParameters[1];
	nY = objectParameters[2];
	nZ = objectParameters[3];
	peelOffFlag = objectParameters[5];

	//if ((objectType == "trefoil knot") || (objectType == "schrek")) {
	if (peelOffFlag) {
		dilationGrowth = -1;
		isoValue = 255;
		copyImageTitle = "CopyImage";
		run("8-bit");
		run("Duplicate...", "title=" + copyImageTitle + " duplicate");
		while(!isOpen(copyImageTitle)) {
		}
		wait(1);
		selectWindow(copyImageTitle);
		if (dilationGrowth > 0) {
			showStatus("Dilating the image ...");
			for (cntr = 0; cntr < dilationGrowth; cntr++) {
				run("Dilate (3D)", "iso=" + isoValue);
				wait(10);
			}
		} else {
			showStatus("Eroding the image ...");
			for (cntr = 0; cntr < - dilationGrowth; cntr++) {
				run("Erode (3D)", "iso=" + isoValue);
				wait(10);
			}
		}
		wait(10);
		showStatus("Generating the shell image ...");
		imageCalculator("XOR stack", imageTitle, copyImageTitle);
		wait(10);
		close(copyImageTitle);
		while(isOpen(copyImageTitle)) {
		}
		wait(1);

		showStatus("Reading the shell pixel values ...");
		Cntr = 0;
		for (z = 0; z < nZ; z++) {
			setSlice(1 + z);
			for (y = 0; y < nY; y++) {
				for (x = 0; x < nX; x++) {
					objectData[Cntr++] = getPixel(x, y);
				}
			}
			showProgress(z, nZ);
		}
		showStatus(" ");
	}
	return objectData;
}

function displayObject(objectData, objectParameters, imageTitle) {
	objectType = toLowerCase(objectParameters[0]);
	nX = objectParameters[1];
	nY = objectParameters[2];
	nZ = objectParameters[3];
	filteredImageFlag = objectParameters[4];
	selectWindow(imageTitle);
	wait(1);
	Stack.getDimensions(imageWidth, imageHeight, imageSlices, imageFrames, imageChannels);	
	showStatus("Setting pixel values ...");
	Array.getStatistics(objectData, minX, maxX, meanX, stdDevX);
	Factor = 255 / (maxX - minX);
	Cntr = 0;
	for (z = 0; z < nZ; z++) {
		setSlice(1 + z);
		for (y = 0; y < nY; y++) {
			for (x = 0; x < nX; x++) {
				setPixel(x, y, floor(Factor * (objectData[Cntr++] - minX)));
			}
		}
		showProgress(z, nZ);
	}
	run("Enhance Contrast" , "saturated=0");
	if (filteredImageFlag) {
		run("3D Fast Filters","filter=Mean radius_x_pix=2.0 radius_y_pix=2.0 radius_z_pix=2.0 Nb_cpus=12");
		run("Enhance Contrast" , "saturated=0");
		close(imageTitle);
		while(isOpen(imageTitle)) {
		}
		wait(1);
		rename(imageTitle);
		while(!isOpen(imageTitle)) {
		}
		wait(1);
	}
	return true;
}

function getObjectVoxels(objectParameters) {
	objectType = toLowerCase(objectParameters[0]);
	nX = objectParameters[1];
	nY = objectParameters[2];
	nZ = objectParameters[3];
	n3D = nX * nY * nZ;
	objectData = newArray(n3D);

	initializeFlag = true;
	if (initializeFlag) {
		showStatus("Initializing pixel values ...");
		Cntr = 0;
		for (z = 0; z < nZ; z++) {
			for (y = 0; y < nY; y++) {
				for (x = 0; x < nX; x++) {
					objectData[Cntr++] = 0;
				}
			}
			showProgress(z, nZ);
		}
		showStatus(" ");
	}

	showStatus("Calculating pixel values ...");
	Cntr = 0;
	if (objectType == "schrek") {
		zThreshold = 5e-1;
		pixelValue = 255;
		for (z = 0; z < nZ; z++) {
			for (y = 0; y < nY; y++) {
				y_ = (PI / 2) * (y / nY);
				for (x = 0; x < nX; x++) {
					x_ = (PI / 2) * (x / nX);
					surfaceEquation = - z + (log(cos(x_) / cos(y_)) + 2) * (nZ / 4);
					if (abs(surfaceEquation) < zThreshold) {
						objectData[Cntr] = pixelValue;
					}
					Cntr++;
				}
			}
			showProgress(z, nZ);
		}
	} else if (objectType == "bagel") {
		zThreshold = 5e-1;
		pixelValue = 255;
		nv = maxOf(maxOf(nX, nY), nZ) * 2;
		nTheta = nv;
		thetaMax = (2 * PI);
		thetaStep = thetaMax / (nTheta - 1);
		vMax = (2 * PI);
		vStep = vMax / (nv - 1);
		r = 3;
		xyOffset = r + 2;
		zOffset = 2;
		xFactor = floor(nX / (2 * xyOffset)) - 2;
		yFactor = floor(nY / (2 * xyOffset)) - 2;
		zFactor = floor(nZ / (2 * zOffset)) - 2;
		for (v = 0; v < vMax; v += vStep) {
			for (theta = 0; theta < thetaMax; theta += thetaStep) {
				x = (r + cos(theta / 2) * sin(v) - sin(theta / 2) * sin(2 * v)) * cos(theta);
				y = (r + cos(theta / 2) * sin(v) - sin(theta / 2) * sin(2 * v)) * sin(theta);
				z = sin(theta / 2) * sin(v) + cos(theta / 2) * sin(2 * v);
				x = floor(xFactor * (x + xyOffset));
				y = floor(yFactor * (y + xyOffset));
				z = floor(zFactor * (z + zOffset));
				if ((z >= nZ) || (z < 0) || (x >= nX) || (x < 0) || (y >= nY) || (y < 0)) {
					print("v = " + v + ", theta = " + theta + ", x = " + x + ", y = " + y + ", z = " + z);
				} else {
					objectData[x + nX * (y + nY * z)] = pixelValue;
				}
			}
			showProgress(v / vStep, vMax / vStep);
		}
	} else if (objectType == "klein bottle") {
		zThreshold = 5e-1;
		pixelValue = 255;
		nv = maxOf(maxOf(nX, nY), nZ) * 2;
		nu = nv;
		uMin = 0.0;
		uMax = (1 * PI) - 1e-4;
		uStep = uMax / (nu - 1);
		vMin = 0.0;
		vMax = (2 * PI) - 1e-4;
		vStep = vMax / (nv - 1);
		a = 1;
		xyOffset = 4 * a;
		zOffset = 0.9 * a;
		xFactor = floor(nX / (2 * xyOffset)) - 1;
		yFactor = floor(nY / (2 * xyOffset)) - 1;
		zFactor = floor(nZ / (2 * zOffset)) - 1;
		coeffA = a * (- 2 / 15);
		coeffB = a * (- 1 / 15);
		coeffC = a * ( 2 / 15);
		for (v = vMin; v < vMax; v += vStep) {
			for (u = uMin; u < uMax; u += uStep) {
				sU = sin(u);
				cU = cos(u);
				sV = sin(v);
				cV = cos(v);
				x = coeffA * cU * (
						3 * cV - 30 * sU + 90 * pow(cU, 4) * sU	- 60 * pow(cU, 6) * sU + 5 * cU * cV * sU
					);
				y = coeffB * sU * (
						3 * cV - 3 * pow(cU, 2) * cV - 48 * pow(cU, 4) * cV + 48 * pow(cU, 6) * cV
						- 60 * sU + 5 * cU * cV * sU - 5 * pow(cU, 3) * cV * sU
						- 80 * pow(cU, 5) * cV * sU + 80 * pow(cU, 7) * cV * sU
					);
				z = coeffC * sV * (
						3 + 5 * cU * sU
					);
				x = floor(xFactor * (x + xyOffset));
				y = floor(yFactor * (y + xyOffset));
				z = floor(zFactor * (z + zOffset));
				if ((z >= nZ) || (z < 0) || (x >= nX) || (x < 0) || (y >= nY) || (y < 0)) {
					print("v = " + v + ", u = " + u + ", x = " + x + ", y = " + y + ", z = " + z);
				} else {
					objectData[x + nX * (y + nY * z)] = pixelValue;
				}
			}
			showProgress(v / vStep, vMax / vStep);
		}
	} else if (objectType == "helicoid") {
		zThreshold = 5e-1;
		pixelValue = 255;
		nv = maxOf(maxOf(nX, nY), nZ) * 6;
		nTheta = nv;
		thetaMax = (2 * PI);
		thetaStep = thetaMax / (nTheta - 1);
		vMax = 1;
		vStep = vMax / (nv - 1);
		Alpha = 4;
		xyOffset = vMax;
		zOffset = 0;
		xFactor = floor(nX / (2 * xyOffset)) - 2;
		yFactor = floor(nY / (2 * xyOffset)) - 2;
		zFactor = floor(nZ / (thetaMax)) - 2;
		for (v = 0; v < vMax; v += vStep) {
			for (theta = 0; theta < thetaMax; theta += thetaStep) {
				x = v * cos(Alpha * theta);
				y = v * sin(Alpha * theta);
				z = theta;
				x = floor(xFactor * (x + xyOffset));
				y = floor(yFactor * (y + xyOffset));
				z = floor(zFactor * (z + zOffset));
				if ((z >= nZ) || (z < 0) || (x >= nX) || (x < 0) || (y >= nY) || (y < 0)) {
					print("v = " + v + ", theta = " + theta + ", x = " + x + ", y = " + y + ", z = " + z);
				} else {
					objectData[x + nX * (y + nY * z)] = pixelValue;
				}
			}
			showProgress(v / vStep, vMax / vStep);
		}
	} else if (objectType == "dini") {
		zThreshold = 5e-1;
		pixelValue = 255;
		nv = maxOf(maxOf(nX, nY), nZ) * 2;
		nu = nv;
		uMax = (6 * PI);
		uStep = uMax / (nu - 1);
		vMin = 0.01;
		vMax = 1;
		vStep = vMax / (nv - 1);
		a = 1;
		b = 0.8;
		xyOffset = a;
		zOffset = 10 * a;
		xFactor = floor(nX / (2 * xyOffset)) - 1;
		yFactor = floor(nY / (2 * xyOffset)) - 1;
		zFactor = floor(nZ / (2 * zOffset)) - 1;
		for (v = vMin; v < vMax; v += vStep) {
			for (u = 0; u < uMax; u += uStep) {
				x = a * sin(v) * cos(u);
				y = a * sin(v) * sin(u);
				z = a * (cos(v) + log(tan(v / 2)) / log(2.71828)) + b * u;
				x = floor(xFactor * (x + xyOffset));
				y = floor(yFactor * (y + xyOffset));
				z = floor(zFactor * (z + zOffset));
				if ((z >= nZ) || (z < 0) || (x >= nX) || (x < 0) || (y >= nY) || (y < 0)) {
					print("v = " + v + ", u = " + u + ", x = " + x + ", y = " + y + ", z = " + z);
				} else {
					objectData[x + nX * (y + nY * z)] = pixelValue;
				}
			}
			showProgress(v / vStep, vMax / vStep);
		}
	} else if (objectType == "trefoil knot") {
		pixelValue = 255;
		nTheta = maxOf(maxOf(nX, nY), nZ) * 6;
		thetaMax = (2 * PI);
		thetaStep = thetaMax / (nTheta - 1);
		xyOffset = 3;
		zOffset = 1;
		xFactor = floor(nX / (2 * xyOffset)) - 2;
		yFactor = floor(nY / (2 * xyOffset)) - 2;
		zFactor = floor(nZ / (2 * zOffset)) - 2;
		for (theta = 0; theta < thetaMax; theta += thetaStep) {
			x = sin(theta) + 2 * sin(2 * theta);
			y = cos(theta) - 2 * cos(2 * theta);
			z = - sin(3 * theta);
			x = floor(xFactor * (x + xyOffset));
			y = floor(yFactor * (y + xyOffset));
			z = floor(zFactor * (z + zOffset));
			if ((z >= nZ) || (z < 0) || (x >= nX) || (x < 0) || (y >= nY) || (y < 0)) {
				print("theta = " + theta + ", x = " + x + ", y = " + y + ", z = " + z);
			} else {
				objectData[x + nX * (y + nY * z)] = pixelValue;
			}
			showProgress(theta / thetaStep, thetaMax / thetaStep);
		}
	} else if (objectType == "double helix") {
		pixelValue = 255;
		nTheta = maxOf(maxOf(nX, nY), nZ) * 6;
		thetaMax = (8 * PI);
		thetaStep = thetaMax / (nTheta - 1);
		xOffset = 1;
		yOffset = 0;
		zOffset = 1;
		circleMargin = 3;
		xFactor = (nX -  2 * circleMargin - 1) / 2;
		yFactor = nY / thetaMax;
		zFactor = (nZ -  2 * circleMargin - 1) / 2;
		for (theta = 0; theta < thetaMax; theta += thetaStep) {
			x = sin(theta);
			z = cos(theta);
			y = theta;
			x = floor(xFactor * (x + xOffset)) + circleMargin;
			y = floor(yFactor * (y + yOffset));
			z = floor(zFactor * (z + zOffset)) + circleMargin;
			if ((z >= nZ) || (z < 0) || (x >= nX) || (x < 0) || (y >= nY) || (y < 0)) {
				print("theta = " + theta + ", x = " + x + ", y = " + y + ", z = " + z);
			} else {
				//pixelValue =  theta;
				objectData[x + nX * (y + nY * z)] = pixelValue;
			}
			
			x = sin(- theta);
			z = cos(- theta);
			y = theta;
			x = floor(xFactor * (x + xOffset)) + circleMargin;
			y = floor(yFactor * (y + yOffset));
			z = floor(zFactor * (z + zOffset)) + circleMargin;
			if ((z >= nZ) || (z < 0) || (x >= nX) || (x < 0) || (y >= nY) || (y < 0)) {
				print("theta = " + theta + ", x = " + x + ", y = " + y + ", z = " + z);
			} else {
				//pixelValue =  theta;
				objectData[x + nX * (y + nY * z)] = pixelValue;
			}

			showProgress(theta / thetaStep, thetaMax / thetaStep);
		}
	} else if (objectType == "mandelbulb") {
		pixelValue = 255;
		n = 8;
		nFractal = 0;
		Cntr = 0;
		for (z = 0; z < nZ; z++) {
			for (y = 0; y < nY; y++) {
				for (x = 0; x < nX; x++) {
					X = x / (nX / 2) - 1;
					Y = y / (nY / 2) - 1;
					Z = z / (nZ / 2) - 1;
					rr = sqrt(X * X + Y * Y + Z * Z);
					phi = atan2(Y, X);
					theta = atan2(sqrt(X * X + Y * Y), Z);
					XYZ = iteratePoint(rr, theta, phi, n);
					if (!isNaN(XYZ[0])) {
						//pixelValue = floor(255 * pow(cos(theta / 2), 2));
						objectData[Cntr] = pixelValue;
					}
					Cntr++;
				}
			}
			showProgress(z, nZ);
		}
	}
	return 	objectData;
}

function getObjectDimensions() {
	typeItems = newArray("Double Helix", "Schrek", "Klein Bottle", "Bagel", "Helicoid", "Dini", "Trefoil Knot", "Mandelbulb");
	nX = 70;
	nY = 200;
	nZ = 70;
	nZrackParams = 6;

	Dialog.create("Track Parameters");
	Dialog.addRadioButtonGroup("Type", typeItems, lengthOf(typeItems), 1, typeItems[0]);
	Dialog.addNumber("Image Width", nX);
	Dialog.addNumber("Image Height", nY);
	Dialog.addNumber("Image Depth", nZ);
	Dialog.addCheckbox("Generate Filtered Image", false);
	Dialog.addCheckbox("Generate Shell", false);
	Dialog.show();

	objectParameters = newArray(nZrackParams);
	objectParameters[0] = Dialog.getRadioButton();
	objectParameters[1] = parseInt(Dialog.getNumber());
	objectParameters[2] = parseInt(Dialog.getNumber());
	objectParameters[3] = parseInt(Dialog.getNumber());
	objectParameters[4] = Dialog.getCheckbox();
	objectParameters[5] = Dialog.getCheckbox();

	return objectParameters;
}

function createStack(objectParameters) {
	objectType = objectParameters[0];
	imageTitle = "3D Object: " + objectType;
	imageType = "8-bit black";
	nX = objectParameters[1];
	nY = objectParameters[2];
	nZ = objectParameters[3];
	newImage(imageTitle, imageType, nX, nY, nZ);
	while (!isOpen(imageTitle)) {
	}
	wait(1);
	return imageTitle;
}

function iteratePoint(rr, theta, phi, n) {
	c = newArray(- 0.1, 0.5, 0.2);
	Threshold = 1e5;
	for (cntr = 0; cntr < n; cntr++) {
		x = pow(rr, n) * sin(n * theta) * cos(n * phi) + c[0];
		y = pow(rr, n) * sin(n * theta) * sin(n * phi) + c[1];
		z = pow(rr, n) * cos(n * theta) + c[2];

		rr = sqrt(pow(x,2) + pow(y,2) + pow(z,2));
		phi = atan2(y, x);
		theta = acos(z / rr);
		if (isNaN(theta)) {
			theta = 0;
		}
		
		if (rr < Threshold) {
			XYZ = newArray(x, y, z);
		} else {
			cntr = n;
			XYZ = newArray(NaN, NaN, NaN);
		}
	}
	return XYZ;
}

function generatePhoto51(imageTitle) {
	selectWindow(imageTitle);
	wait(1);
	imWidth = getWidth;
	imHeight = getHeight;
	imWidth_ = 2 * imWidth;
	imHeight_ = 2 * imHeight;
	
	run("32-bit");
	nImages_ = nImages;
	run("Z Project...", "projection=[Sum Slices]");
	while(nImages_ == nImages) {
	}
	nImages_ = nImages;
	projectionTitle = "Double-helix projection";
	rename(projectionTitle);
	//run("Macro...", "code=[v = v * (0.54 - 0.46 * cos(2 * PI * (1 / (w - 1)) * x)) * (0.54 - 0.46 * cos(2 * PI * (1 / (h - 1)) * y))]");
	run("Canvas Size...", "width=" + imWidth_ + " height=" + imHeight_ + " position=Center zero");
	while(imWidth_ != getWidth) {
	}
	run("FFT Options...", "raw do");
	while(nImages_ == nImages) {
	}
	nImages_ = nImages;
	run("8-bit");
	ftTitle = "\"Photo 51\"";
	rename(ftTitle);
	run("Canvas Size...", "width=" + imWidth + " height=" + imHeight + " position=Center zero");
	ftWidth = getWidth;
	ftHeight = getHeight;
	ftAll = ftWidth * ftHeight;
	ftData = newArray(ftAll);
	for (y = 0; y < ftHeight; y++) {
		for (x = 0; x < ftWidth; x++) {
			ftData[x + y * ftWidth] = getPixel(x, y);
		}
	}
	close(ftTitle);
	while(isOpen(ftTitle)) {
	}
	wait(1);
	newImage(ftTitle, "8-bit black", ftWidth, ftHeight, 1);
	while(!isOpen(ftTitle)) {
	}
	for (y = 0; y < ftHeight; y++) {
		for (x = 0; x < ftWidth; x++) {
			setPixel(x, y, ftData[x + y * ftWidth]);
		}
	}
	run("Invert LUT");		
	run("Enhance Contrast", "saturated=0.35");
	photo51Text = "Photo 51";
	fontSize = 18;
	setFont("SansSerif" , fontSize, "antialiased");
	run("RGB Color");
	setColor(255, 0, 0);
	drawString(photo51Text, floor((getWidth - getStringWidth(photo51Text)) / 2), fontSize * 2);

	selectWindow(projectionTitle);
	run("Canvas Size...", "width=" + imWidth + " height=" + imHeight + " position=Center zero");
	while(imWidth != getWidth) {
	}
	run("Enhance Contrast", "saturated=0.35");
	run("RGB Color");
	run("Combine...", "stack1=[" + projectionTitle + "] stack2=[" + ftTitle + "]");
}

