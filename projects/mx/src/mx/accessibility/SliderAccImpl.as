
package mx.accessibility
{

import flash.accessibility.Accessibility;
import flash.events.Event;
import flash.events.FocusEvent;

import mx.accessibility.AccConst;
import mx.controls.sliderClasses.Slider;
import mx.core.UIComponent;
import mx.core.mx_internal;
import mx.events.SliderEvent;

use namespace mx_internal;
	
/**
 *  SliderAccImpl is a subclass of AccessibilityImplementation
 *  which implements accessibility for the Slider class.
 *  
 *  @langversion 3.0
 *  @playerversion Flash 9
 *  @playerversion AIR 1.1
 *  @productversion Flex 3
 */
public class SliderAccImpl extends AccImpl
{
	include "../core/Version.as";

	//--------------------------------------------------------------------------
	//
	//  Class methods
	//
	//--------------------------------------------------------------------------

	/**
	 *  Enables accessibility in the Slider class.
	 * 
	 *  <p>This method is called by application startup code
	 *  that is autogenerated by the MXML compiler.
	 *  Afterwards, when instances of Slider are initialized,
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
		Slider.createAccessibilityImplementation =
			createAccessibilityImplementation;
	}

	/**
	 *  @private
	 *  Creates a Slider's AccessibilityImplementation object.
	 *  This method is called from UIComponent's
	 *  initializeAccessibility() method.
	 */
	mx_internal static function createAccessibilityImplementation(
								component:UIComponent):void
	{
		component.accessibilityImplementation =
			new SliderAccImpl(component);
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
	public function SliderAccImpl(master:UIComponent)
	{
		super(master);

		role = AccConst.ROLE_SYSTEM_SLIDER;

		master.addEventListener(FocusEvent.FOCUS_IN, focusInHandler);
	}
	
	//--------------------------------------------------------------------------
	//
	//  Overridden properties: AccImpl
	//
	//--------------------------------------------------------------------------

	//----------------------------------
	//  eventsToHandle
	//----------------------------------

	/**
	 *  @private
	 *	Array of events that we should listen for from the master component.
	 */
	override protected function get eventsToHandle():Array
	{
		return super.eventsToHandle.concat([ "change" ]);
	}
	
	//--------------------------------------------------------------------------
	//
	//  Overridden methods: AccessibilityImplementation
	//
	//--------------------------------------------------------------------------

	/**
	 *  @private
	 *  Gets the role for the component.
	 *
	 *  @param childID uint.
	 */
	override public function get_accRole(childID:uint):uint
	{
		return role;
	}
	
		/**
	 *  @private
	 *  IAccessible method for returning the value of the slider
	 *  (which would be the value of the item selected).
	 *  The slider should return the value of the current thumb as the value.
	 *
	 *  @param childID uint
	 *
	 *  @return Value String
	 */
	override public function get_accValue(childID:uint):String
	{
		var val:Number = Slider(master).values[Math.max(childID - 1, 0)];

		val = (val -  Slider(master).minimum) /
			  (Slider(master).maximum - Slider(master).minimum) * 100;
		
		return String(val) + " percent";
	}
	
	/**
	 *  @private
	 *  Method to return an array of childIDs.
	 *
	 *  @return Array
	 */
	override public function getChildIDArray():Array
	{
		var n:int = Slider(master).thumbCount;

		return createChildIDArray(n);
	}

	/**
	 *  @private
	 *  method for returning the name of the slider
	 *  should return the value
	 *
	 *  @param childID uint
	 *
	 *  @return Name String
	 */
	override protected function getName(childID:uint):String
	{
		return "";
	}

	/**
	 *  @private
	 *  IAccessible method for returning the state of the Button.
	 *  States are predefined for all the components in MSAA.
	 *  Values are assigned to each state.
	 *
	 *  @param childID uint
	 *
	 *  @return State uint
	 */
	override public function get_accState(childID:uint):uint
	{
		var accState:uint = getState(childID);
		accState |= AccConst.STATE_SYSTEM_SELECTABLE;
		if (childID == 0)
			accState |=  AccConst.STATE_SYSTEM_SELECTED;
		else 
			accState |=  AccConst.STATE_SYSTEM_SELECTED | AccConst.STATE_SYSTEM_FOCUSED;
		return accState;
	}
	
	/**
	 *  Utility method determines state of the accessible component.
	 *  
	 *  @langversion 3.0
	 *  @playerversion Flash 9
	 *  @playerversion AIR 1.1
	 *  @productversion Flex 3
	 */
	override protected function getState(childID:uint):uint
	{
		var accState:uint = AccConst.STATE_SYSTEM_NORMAL;
		
		if (!UIComponent(master).enabled)
			accState |= AccConst.STATE_SYSTEM_UNAVAILABLE;
		else
		{
			accState |= AccConst.STATE_SYSTEM_FOCUSABLE
			
			for (var i:uint = 0; i < Slider(master).thumbCount; i++)
			{
				if (Slider(master).getThumbAt(i) == Slider(master).focusManager.getFocus())
				{
					//trace("has focus", UIComponent(master),  UIComponent(master).getFocus());
					accState |= AccConst.STATE_SYSTEM_FOCUSED;
					break;
				}
			}
		}
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
	 *  All AccImpl must implement this to listen
	 *  for events from its master component. 
	 */
	override protected function eventHandler(event:Event):void
	{
		// Let AccImpl class handle the events
		// that all accessible UIComponents understand.
		$eventHandler(event);

		switch (event.type)
		{
			case "change":
			{
				var childID:uint = SliderEvent(event).thumbIndex + 1;
				Accessibility.sendEvent(master, 0, AccConst.EVENT_OBJECT_SELECTION);
				Accessibility.sendEvent(master, 0,
										AccConst.EVENT_OBJECT_VALUECHANGE, true);
				break;
			} 
		}
	}
	
	/**
	 *  @private
	 *  This is (kind of) a hack to get around the fact that Slider is not 
	 *  an IFocusManagerComponent. It forces frocus from accessibility when one of 
	 *  its thumbs get focus. 
	 */
	private function focusInHandler(event:Event):void
	{
		Accessibility.sendEvent(master, 0, AccConst.EVENT_OBJECT_FOCUS);
	}
}
}
