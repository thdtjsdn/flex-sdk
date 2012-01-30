////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2004-2007 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package mx.accessibility
{

import flash.accessibility.Accessibility;
import flash.events.Event;
import flash.events.MouseEvent;
import mx.accessibility.AccConst;
import mx.containers.Panel;
import mx.containers.TitleWindow;
import mx.core.UIComponent;
import mx.core.mx_internal;

use namespace mx_internal;

/**
 *  TitleWindowAccImpl is a subclass of AccessibilityImplementation
 *  which implements accessibility for the TitleWindow class.
 *  
 *  @langversion 3.0
 *  @playerversion Flash 9
 *  @playerversion AIR 1.1
 *  @productversion Flex 3
 */
public class TitleWindowAccImpl extends PanelAccImpl
{
    include "../core/Version.as";

	//--------------------------------------------------------------------------
	//
	//  Class methods
	//
	//--------------------------------------------------------------------------

	/**
	 *  Enables accessibility in the TitleWindow class.
	 * 
	 *  <p>This method is called by application startup code
	 *  that is autogenerated by the MXML compiler.
	 *  Afterwards, when instances of TitleWindow are initialized,
	 *  their <code>accessibilityImplementation</code> property
	 *  will be set to an instance of this class.</p>
	 *  
	 *  @langversion 3.0
	 *  @playerversion Flash 9
	 *  @playerversion AIR 1.1
	 *  @productversion Flex 3
	 */
	public static function enableAccessibility():void
	{
		TitleWindow.createAccessibilityImplementation =
			createAccessibilityImplementation;
	}

	/**
	 *  @private
	 *  Creates a TitleWindow's AccessibilityImplementation object.
	 *  This method is called from UIComponent's
	 *  initializeAccessibility() method.
	 */
	mx_internal static function createAccessibilityImplementation(
								component:UIComponent):void
	{
		// The AccessibilityImplementation is placed on the
		// TitleWindow's titleBar, not on the TitleWindow itself.
		// If it were placed on the TitleWindow itself,
		// the AccessibilityImplementations of the TitleWindow's children
		// would be ignored.
		var titleBar:UIComponent = TitleWindow(component).getTitleBar();
		titleBar.accessibilityImplementation =
			new TitleWindowAccImpl(component);

		Accessibility.sendEvent(titleBar, 0, AccConst.EVENT_OBJECT_CREATE);
		Accessibility.updateProperties();
	}

	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------

	/**
	 *  Constructor.
	 *
	 *  @param master The UIComponent instance that this AccImpl instance
	 *  is making accessible.
	 *  
	 *  @langversion 3.0
	 *  @playerversion Flash 9
	 *  @playerversion AIR 1.1
	 *  @productversion Flex 3
	 */
	public function TitleWindowAccImpl(master:UIComponent)
	{
		super(master);
		
		// Typecasting as Panel and not TitleWindow since AlertAccImpl
		// also extends from this but Alert is not a subclass of TitleWindow
		// but is of Panel.
		
		Panel(master).getTitleBar().addEventListener(MouseEvent.MOUSE_UP,
													 eventHandler);
		
		Panel(master).closeButton.addEventListener(MouseEvent.MOUSE_UP,
												   eventHandler);
	}
	
	//--------------------------------------------------------------------------
	//
	//  Overridden methods: AccessibilityImplementation
	//
	//--------------------------------------------------------------------------

	/**
	 *  @private
	 *  IAccessible method for returning the state of the TitleWindow.
	 *  States are predefined for all the components in MSAA.
	 *  Values are assigned to each state.
	 *  Depending upon the TitleWindow being Focusable, Focused and Moveable,
	 *  a value is returned.
	 *
	 *  @param childID:uint
	 *
	 *  @return State:uint
	 */
	override public function get_accState(childID:uint):uint
	{
		var accState:uint = getState(childID);
		
		accState |= AccConst.STATE_SYSTEM_MOVEABLE;
		
		return accState;
	}
	
	//--------------------------------------------------------------------------
	//
	//  Overridden event handlers: AccImpl
	//
	//--------------------------------------------------------------------------

	/**
	 *  @private
	 *  Override the generic event handler.
	 *  All AccImpl must implement this
	 *  to listen for events from its master component. 
	 */
	override protected function eventHandler(event:Event):void
	{
		// Let AccImpl class handle the events
		// that all accessible UIComponents understand.
		$eventHandler(event);

		switch (event.type)
		{
			case MouseEvent.MOUSE_UP:
			{
				if (event.target == Panel(master).getTitleBar())
				{
					Accessibility.sendEvent(Panel(master).getTitleBar(), 0,
											AccConst.EVENT_OBJECT_LOCATIONCHANGE, true);
				}

				if (event.target == Panel(master).closeButton)
				{
					Accessibility.sendEvent(Panel(master).getTitleBar(), 0,
											AccConst.EVENT_OBJECT_DESTROY, true);
				}

				Accessibility.updateProperties();
				break;
			}
		}
	}
}

}
