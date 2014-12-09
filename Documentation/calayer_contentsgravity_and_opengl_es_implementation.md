# CALayer contentsGravity and OpenGL ES implementation

## The Concept

``contentsGravity`` control how the layer's contents are positioned or scaled within its bounds

there has 12 values:

*   kCAGravityCenter 
*   kCAGravityTop 
*   kCAGravityBottom 
*   kCAGravityLeft 
*   kCAGravityRight 
*   kCAGravityTopLeft 
*   kCAGravityTopRight 
*   kCAGravityBottomLeft 
*   kCAGravityBottomRight 
*   kCAGravityResize 
*   kCAGravityResizeAspect 
*   kCAGravityResizeAspectFill

---

## the OpenGL ES rendering

the layer's contents are consider as a texture

texture controlled by two variable:  ``vertices`` and ``texturecoordinate`` 

* ``vertices`` presents texture's size
* ``texturecoordinate`` the area of contents to draw in vertices

texturecoordinate value from 0 to 1.0

to draw layer's contents, first we needs know the ``contentsSize``

for position-only gravity value:

* if ``contentsSize`` large than ``boundsSize``
	* ``maskToBounds`` just works
	* ``contentsRect`` will be ``texturecoordinate``
	* ``contentsScale`` ?? //physical size (w,h), logical size is defined as '(w /
 * contentsScale, h / contentsScale)'
	* ``contentsCenter`` ?? 
* if ``contentsSize`` less than ``boundsSize``
	* maskToBounds just works
	* contentsRect works

vertices cacluate:

* for default resize, it's equal to bounds
* for aspect resize , calcuate width and height raito, 
	* for fit mode, chose small one, 
	* for fill mode, chose large one
	
for position mode
* size equal to texture logic size
* adjust origin to match mode

to support ```contentsGravity```, we needs know contents size, and calculate texturecoordinate






