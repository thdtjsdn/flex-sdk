////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2008 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package mx.components
{
import flash.ui.Keyboard;
import mx.layout.ILayoutItem;
import mx.layout.LayoutItemFactory;
import mx.components.baseClasses.FxScrollBar;	

/**
 *  The VScrollBar (vertical ScrollBar) control lets you control
 *  the portion of data that is displayed when there is too much data
 *  to fit vertically in a display area.
 * 
 *  <p>This control extends the base ScrollBar control.</p> 
 *  
 *  <p>Although you can use the VScrollBar control as a stand-alone control,
 *  you usually combine it as part of another group of components to
 *  provide scrolling functionality.</p>
 */
public class FxVScrollBar extends FxScrollBar
{
    include "../core/Version.as";

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Constructor. 
     */    
    public function FxVScrollBar()
    {
        super();
    }
    
    //--------------------------------------------------------------------------
    //
    //  Overridden properties
    //
    //--------------------------------------------------------------------------

    /**
     *  The size of the track on a VScrollBar equals the height of the track.
     */
    override protected function get trackSize():Number
    {
        if (track)
            return track.height;
        else
            return 0;
    }
    
    //--------------------------------------------------------------------------
    //
    // Methods
    //
    //--------------------------------------------------------------------------

    /**
     *  Position the thumb button according to the given thumbPos parameter,
     *  relative to the current y location of the track in the scrollbar control.
     * 
     *  @param thumbPos A number representing the new position of the thumb
     *  button in the control.
     */
    override protected function positionThumb(thumbPos:Number):void
    {
        if (thumb)
        {
            var trackPos:Number = track ? track.y : 0;
            var layoutItem:ILayoutItem = LayoutItemFactory.getLayoutItemFor(thumb);
            layoutItem.setActualPosition(layoutItem.actualPosition.x,
            					    	 Math.round(trackPos + thumbPos));
        }
    }

    /**
     *  @private
     */
    override protected function calculateThumbSize():Number
    {
        return Math.max(thumb.minHeight, super.calculateThumbSize());
    }

    /**
     *  @private
     */
    override protected function sizeThumb(thumbSize:Number):void
    {
        thumb.height = thumbSize;
    }
    
    /**
     *  The position of the thumb on a VScrollBar is equal to the given
     *  localY parameter.
     * 
     *  @param localX The x position relative to the scrollbar control
     *  @param localY The y position relative to the scrollbar control
     */
    override protected function pointToPosition(localX:Number, 
                                                localY:Number):Number
    {
        return localY;
    }
    
    
    /**
     *  Implicitly update the viewport's verticalScrollPosition per the
     *  specified scrolling unit, by setting the scrollbar's value.
     *
     *  @private
     */
    private function updateViewportVSP(unit:uint):void
    {
        var delta:Number = viewport.verticalScrollPositionDelta(unit);
        setValue(viewport.verticalScrollPosition + delta);
    }
    
    /**
     *  If viewport is non null then ask it to compute the vertical
     *  scroll position delta for page up/down.  The delta is added
     *  to this scrollbar's value. 
     * 
     *  @see viewport
     *  @see #setValue
     *  @see IViewport#verticalScrollPositionDelta
     */
    override public function page(increase:Boolean = true):void
    {
        if (!viewport)
            super.page(increase);
        else
            updateViewportVSP((increase) ? Keyboard.PAGE_DOWN : Keyboard.PAGE_UP);
    }
    
    /**
     *  If viewport is non null then ask it to compute the verical
     *  scroll position delta for step up/down.  The delta is added
     *  to this scrollbar's value.  
     * 
     *  @see viewport
     *  @see #setValue
     *  @see IViewport#verticalScrollPositionDelta
     */
    override public function step(increase:Boolean = true):void
    {
        if (!viewport)
            super.step(increase);
        else
            updateViewportVSP((increase) ? Keyboard.DOWN : Keyboard.UP);
    }    
    
}

}