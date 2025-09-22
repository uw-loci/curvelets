// CurveAlign Analysis Results Macro
// Generated automatically from Python API

// Open image
open("test.tif");

// Analysis summary
print("CurveAlign Analysis Results:");
print("Curvelets detected: 8");
print("Mean angle: 78.8 degrees");
print("Alignment index: -0.177");

// Add curvelet overlays

makeLine(6.1, 0.1, 19.9, 5.9);
setForegroundColor("orange");
run("Draw", "slice");

makeLine(17.1, 12.1, 30.9, 17.9);
setForegroundColor("orange");
run("Draw", "slice");

makeLine(10.9, 28.1, -2.9, 33.9);
setForegroundColor("blue");
run("Draw", "slice");

makeLine(21.9, 17.1, 16.1, 30.9);
setForegroundColor("green");
run("Draw", "slice");

makeLine(26.9, 5.1, 21.1, 18.9);
setForegroundColor("green");
run("Draw", "slice");

makeLine(22.1, 10.1, 27.9, 23.9);
setForegroundColor("yellow");
run("Draw", "slice");

makeLine(25.1, 17.1, 30.9, 30.9);
setForegroundColor("yellow");
run("Draw", "slice");

makeLine(16.1, 18.1, 21.9, 31.9);
setForegroundColor("yellow");
run("Draw", "slice");

// Save results
saveAs("PNG", "curvealign_imagej_overlay.png");
