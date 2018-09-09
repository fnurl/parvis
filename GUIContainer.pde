import java.util.List;

class GUIContainer {
  
  ArrayList<GUIComponent> components;
  
  GUIContainer() {
    this.components = new ArrayList();
  }
  
  void add(GUIComponent component) {
    this.components.add(component);
  }
  
  /**
   * Update all GUI components.
   * Track all mouse input and fire component events as needed:
   * - mouse enter: .componentEntered()
   * - mouse out: .componentExited()
   * - mouse pressed: .componentPressed() (possibly drag start)
   * - mouse released outside: .componentReleasedOutside() (implicitly drag end)
   * - mouse released inside: .componentReleasedInside() (possibly drag end, or click)
   * - mouse dragged: .componentDragged()
   */
  void updateGUI() {
    for(GUIComponent component : this.components) {
      
      // mouse stuff
      
      // component event handlers to call if mouse is over component
      if (component.isMouseOver()) {
       
        // ENTER
        // if component was not tracking mouse entered, tell it to do so
        if (!component.trackMouseEnter) {
          component.trackMouseEnter = true;
          component.componentEntered();
        }

        // PRESSED
        // if entered and mouse pressed and component not already tracking button,
        // inform component that it is tracking the mouse button
        if (mousePressed && !component.trackMouseButton) {
          component.trackMouseButton = true;
          component.mousePressedX = mouseX;
          component.mousePressedY = mouseY;
          component.componentPressed();
        }
        
        // RELEASE INSIDE
        // if entered and component tracking mouse button and mouse is not pressed
        // inform component that it mousebutton was released inside
        if (!mousePressed && component.trackMouseButton) {
          component.trackMouseButton = false;
          component.componentReleasedInside();

          // DRAG END
          if (component.trackDragging) {
            component.trackDragging = false;
            component.componentDragEnded();
            component.dragVector = null;
            component.deltaVector = null;
          }
          // CLICK: if not tracking drag, we have a click!
          else {
            component.componentClicked();
          }

          // forget where component was pressed
          component.mousePressedX = -1;
          component.mousePressedY = -1;

        }
      }
     
      // component event handlers to call if mouse is not over component
      if (!component.isMouseOver()) {
      
        // EXIT
        // inform that mouse has left if component was tracking that
        if (component.trackMouseEnter) {
          component.trackMouseEnter = false;
          component.componentExited();
        }
      
        // RELEASE OUTSIDE
        // if component was tracking mouse button and mouse released
        if (component.trackMouseButton && !mousePressed) {
          component.trackMouseButton = false;
          component.componentReleasedOutside();
          // forget where component was pressed
          component.mousePressedX = -1;
          component.mousePressedY = -1;

          // DRAG END
          if (component.trackDragging) {
            component.trackDragging = false;
            component.componentDragEnded();
            component.dragVector = null;
            component.deltaVector = null;
          }
        }
      }
      
      // component event handlers to call if component is tracking mouse button
      if (component.trackMouseButton) {

        // DRAGGING
        // if component is tracking mouse button and mouse moved since last frame
        // inform component that it is being dragged
        if (mouseX != pmouseX || mouseY != pmouseY) {
          int mouseDeltaX = mouseX - pmouseX;
          int mouseDeltaY = mouseY - pmouseY;
          int dragX = mouseX - component.mousePressedX;
          int dragY = mouseY - component.mousePressedY;

          // DRAG START
          if (!component.trackDragging) {
            component.trackDragging = true;
            component.deltaVector = new PVector(mouseDeltaX, mouseDeltaY);
            component.dragVector = new PVector(dragX, dragY);
            component.componentDragStart();
          }
          // CONTINUE DRAG
          else {
            component.deltaVector.set(mouseDeltaX, mouseDeltaY);
            component.dragVector.set(dragX, dragY);
            component.componentDragged();
          }
        }
      }
      
      // draw component
      component.draw();
    }
  }
}
