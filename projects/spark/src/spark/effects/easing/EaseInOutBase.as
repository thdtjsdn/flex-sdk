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
package spark.effects.easing
{
/**
 * The superclass for classes that provide easing capability where there
 * is an easing-in portion of the animation followed by an easing-out portion.
 * The default behavior of this class will simply return a linear
 * interpolation for both easing phases; developers should create a subclass
 * of EaseInOutBase to get more interestion behavior.
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
public class EaseInOutBase implements IEaser
{

    /**
     * Constructs an EaseInOutBase instance with an optional easeInFraction
     * parameter.
     * 
     * @param easeInFraction Optional parameter that sets the value of
     * the <code>easeInFraction</code> property. The default value is
     * <code>EasingFraction.IN_OUT</code>, which eases in for the first half
     * of the time and eases out for the remainder.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function EaseInOutBase(easeInFraction:Number = EasingFraction.IN_OUT)
    {
        this.easeInFraction = easeInFraction;
    }

    /**
     * Storage for the _easeInFraction property
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    private var _easeInFraction:Number = .5;
    
    /**
     * The percentage of an animation that should be spent accelerating. 
     * This factor sets an implicit
     * "easeOut" parameter, equal to (1 - easeIn), so that any time not
     * spent easing in is spent easing out. For example, to have an easing
     * equation that spends half the time easing in and half easing out,
     * set easeIn equal to .5.
     * 
     * @see IN
     * @see OUT
     * @see IN_OUT
     * 
     * @default .5
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function get easeInFraction():Number
    {
        return _easeInFraction;
    }
    public function set easeInFraction(value:Number):void
    {
        _easeInFraction = value;
    }

    /**
     * @inheritDoc
     * 
     * Calculates the eased fraction value based on the 
     * <code>easeInFraction</code> property. If the given
     * <code>fraction</code> is less than <code>easeInFraction</code>,
     * this will call the <code>easeIn()</code> function, otherwise it
     * will call the <code>easeOut()</code> function. It is expected
     * that these functions are overridden in a subclass.
     * 
     * @param fraction The elapsed fraction of the animation
     * @return The eased fraction of the animation
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function ease(fraction:Number):Number
    {
        var easeOutFraction:Number = 1 - easeInFraction;
        
        if (fraction <= easeInFraction && easeInFraction > 0)
            return easeInFraction * easeIn(fraction/easeInFraction);
        else
            return easeInFraction + easeOutFraction * 
                easeOut((fraction - easeInFraction)/easeOutFraction);
    }
    
    /**
     * Returns a value that represents the eased fraction during the 
     * ease-in part of the curve. The value returned by this class 
     * is simply the fraction itself, which represents a linear 
     * interpolation of the fraction. More interesting behavior is
     * implemented by subclasses of <code>EaseInOutBase</code>.
     * 
     * @param fraction The fraction elapsed of the easing-in portion
     * of the animation.
     * @return A value that represents the eased value for this
     * part of the animation.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    protected function easeIn(fraction:Number):Number
    {
        return fraction;
    }
    
    /**
     * Returns a value that represents the eased fraction during the 
     * ease-out part of the curve. The value returned by this class 
     * is simply the fraction itself, which represents a linear 
     * interpolation of the fraction. More interesting behavior is
     * implemented by subclasses of <code>EaseInOutBase</code>.
     * 
     * @param fraction The fraction elapsed of the easing-out portion
     * of the animation.
     * @return A value that represents the eased value for this
     * part of the animation.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    protected function easeOut(fraction:Number):Number
    {
        return fraction;
    }
    
}
}