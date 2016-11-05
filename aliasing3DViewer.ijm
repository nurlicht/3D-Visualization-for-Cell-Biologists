/**
 * Demonstrates the distortions in the rendered 3D image caused by insufficient sampling of surfaces parallel to the direction of view. The take-home message is to look an object from different angles and consider the points with normal view (at any orientation) as the most reliable ones.
 * Program		Aliasing_3DViewer.java
 * @author		Aliakbar Jafarpour <jafarpour.a.j@ieee.org>
 * Affiliation	Center for Molecular Biology at University of Heidelberg (ZMBH)
 * @version		1.0 
 * @param
 * @return
 */

import ij.*;
import ij.gui.*;
import ij.plugin.PlugIn;
import ij.process.*;
import ij3d.*;

public class Aliasing_3DViewer implements PlugIn {
	private ImagePlus imp;

	public void run(String arg) {
		new Initialize();
		this.createEmptyStack();
		this.createDoubleSheet();
		this.animateDoubleSheet();
	}

	private void createEmptyStack() {
		int nX = 200;
		int nY = 200;
		int nZ = 200;
		String imageName = "Double_Sheet";
		this.imp = NewImage.createByteImage(imageName, nX, nY, nZ, NewImage.FILL_BLACK);
	}

	private void createDoubleSheet() {
		ImageProcessor im = imp.getProcessor();
		im.setColor((int) 16777215);
		imp.setSlice(1);
		im.fill();
		imp.setSlice(imp.getNSlices());
		im.fill();
		imp.show();
	}
	
	private void animateDoubleSheet() {
		String imageName = imp.getTitle();
		IJ.run("3D Viewer", "");
		ImageJ3DViewer.setCoordinateSystem("false");
		ImageJ3DViewer.add(imageName, "None", imageName, "0", "true", "true", "true", "1", "0");
		ImageJ3DViewer.select(imageName);
		ImageJ3DViewer.setTransform("0.3957328 0.8860198 0.24158749 -52.036102 -0.7248819 0.4628736 -0.51019055 176.21109 -0.5638634 0.026776686 0.82543397 70.760185 0.0 0.0 0.0 1.0");
		ImageJ3DViewer.startAnimate();
	}
}

class Initialize {
	public Initialize() {
		IJ.run("Close All");
	}
}
// Program: aliasing3DViewer.ijm
// Version: 1
// Programming language: ImageJ Macro
// Description: Demonstrates the distortions in the rendered 3D image caused by insufficient sampling of surfaces parallel to the direction of view. The take-home message is to look an object from different angles and consider the points with normal view (at any orientation) as the most reliable ones.

// Programmer: Aliakbar Jafarpour
// Affiliation: Center for Molecular Biology at University of Heidelberg (ZMBH)
// Email: jafarpour.a.j@ieee.org

macro "Main" {
	Initialize();
	imageName = createDoubleSheet();
	animateDoubleSheet(imageName);
}

function Initialize() {
  	setBatchMode(false);
	print("\\Clear");
	if (nImages > 0) {
		run("Close All");
		while (nImages > 0) {
		}
		wait(1);
	}
	if (nResults > 0) {
		run("Clear Results");
	}
	if (isOpen("Results")) {
		selectWindow("Results");
		run("Close");
	}
	wait(1);
	waitForUser("Please close all 3D Viewer Windows (if any) and THEN click OK.");
	wait(1000);
}

function createDoubleSheet() {
	nX = 200;
	nY = 200;
	nZ = 200;
	imageName = "Double_Sheet";
	newImage(imageName, "8-bit black", nX, nY, nZ);
	setForegroundColor(255, 255, 255);
	run("Select All");
	setSlice(1);
	run("Fill", "slice");
	setSlice(nZ);
	run("Fill", "slice");
	run("Select None");
	return imageName;
}

function animateDoubleSheet(imageName) {
	Delay = 2000;
	run("3D Viewer");
	wait(Delay);
	call("ij3d.ImageJ3DViewer.setCoordinateSystem", "false");
	call("ij3d.ImageJ3DViewer.add", imageName, "None", imageName, "0", "true", "true", "true", "1", "0");
	wait(Delay);
	call("ij3d.ImageJ3DViewer.select", "Double_Sheet");	
	wait(Delay);
	call("ij3d.ImageJ3DViewer.setTransform", "0.3957328 0.8860198 0.24158749 -52.036102 -0.7248819 0.4628736 -0.51019055 176.21109 -0.5638634 0.026776686 0.82543397 70.760185 0.0 0.0 0.0 1.0 ");
	wait(Delay);
	call("ij3d.ImageJ3DViewer.startAnimate");	
}
