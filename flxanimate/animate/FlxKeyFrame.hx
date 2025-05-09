package flxanimate.animate;

import flxanimate.effects.FlxColorEffect;
import flixel.math.FlxMatrix;
import flixel.graphics.frames.FlxFrame;
import openfl.display.Sprite;
import openfl.filters.BitmapFilter;
import openfl.utils.Function;
import haxe.extern.EitherType;
import flixel.FlxG;
import flixel.math.FlxMath;
import openfl.geom.ColorTransform;
import flxanimate.data.AnimationData;
import flxanimate.animate.FlxLayer;

class FlxKeyFrame
{
    public var name(default, set):Null<String>;

    @:allow(flxanimate.FlxAnimate)
    var _filterFrame:FlxFrame;
    
    @:allow(flxanimate.FlxAnimate)
    var _bitmapMatrix:FlxMatrix;

    @:allow(flxanimate.animate.FlxSymbol)
    @:allow(flxanimate.FlxAnimate)
    var callbacks(default, null):Array<Function>;
    @:allow(flxanimate.animate.FlxLayer)
    var _parent:FlxLayer;

    public var index(default, set):Int;
    public var duration(default, set):Int;
    public var colorEffect(default, set):FlxColorEffect;

    @:allow(flxanimate.FlxAnimate)
    var _elements(default, null):Array<FlxElement>;

    @:allow(flxanimate.FlxAnimate)
    var _renderDirty:Bool = false;

    @:allow(flxanimate.FlxAnimate)
    var _ff:Int = -1;

    public var filters(default, set):Array<BitmapFilter>;

    public function new(index:Int, ?duration:Int = 1, ?elements:Array<FlxElement> = null, ?colorEffect:FlxColorEffect = null, ?name:String = null)
    {
        this.index = index;
        this.duration = duration;
        
        this.name = name;
        _elements = (elements == null) ? [] : elements;
        this.colorEffect = colorEffect;
        callbacks = [];
        _bitmapMatrix = new FlxMatrix();
    }
    
    function set_duration(duration:Int)
    {
        var difference:Int = cast this.duration - FlxMath.bound(duration, 1);
        this.duration = cast FlxMath.bound(duration, 1);
        if (_parent != null)
        {
            var frame = _parent.get(index + duration);
            if (frame != null)
                frame.index -= difference;
        }
        return duration;
    }
    function set_filters(value:Array<BitmapFilter>)
    {
        _renderDirty = true;

        return filters = value;
    }

    public function update(frame:Int)
    {

        if (filters == null || filters.length == 0 || _renderDirty) return;

        for (filter in filters)
        {
            @:privateAccess
            if (filter.__renderDirty)
            {
                _renderDirty = true;
                return;
            }
        }

        for (element in _elements)
        {
            if (element.symbol == null) continue;
            
            if (element.symbol._renderDirty || element.symbol._layerDirty)
            {
                _renderDirty = true;
                return;
            }
        }
    }
    public function add(element:EitherType<FlxElement, Function>)
    {   
        if (element is FlxElement)
        {
            var element:FlxElement = element;
            if (element == null)
            {
                FlxG.log.error("this element is null!");
                return null;
            }
            element._parent = this;
            _elements.push(element);
        }
        else
        {
            if (element == null)
            {
                FlxG.log.error("this callback is null!");
                return null;
            }
            callbacks.push(element);
        }

        return element;
    }
    public function get(element:Int)
    {
        return _elements[element];
    }
    public function getList()
    {
        return _elements;
    }
    public function remove(element:EitherType<FlxElement, Function>)
    {
        if (element == null) return null;

        if (element is FlxElement)
        {
            if (element == null || !_elements.remove(element))
            {
                FlxG.log.error("this element doesn't exist!");
                return null;
            }
        }
        else
        {
            if (element == null || !callbacks.remove(element))
            {
                FlxG.log.error("this callback doesn't exist!");
                return null;
            }
        }
        return element;
    }
    public function fireCallbacks()
    {
        var i = 0;
        while (i < callbacks.length)
        { 
            callbacks[i]();
            i++;
        }
    }
    public function removeCallbacks()
    {
        callbacks = [];
    }
    public function clone()
    {
        var keyframe = new FlxKeyFrame(duration, _elements, colorEffect, name);
        keyframe.callbacks = callbacks;
        return keyframe;
    }

    public function destroy() 
    {
        name = null;
        index = 0;
        duration = 0;
        callbacks = null;
        _parent = null;
        colorEffect = null;
        for (element in _elements)
        {
            element.destroy();
        }
    }

    public function toString()
    {
        return '{index: $index, duration: $duration}';
    }
    function set_colorEffect(value:EitherType<ColorEffect, FlxColorEffect>)
    {
        if (value == null)
            value = None;
        if (value is ColorEffect)
            colorEffect = AnimationData.parseColorEffect(value);
        else
            colorEffect = value;

        return colorEffect;
    }
    
    function set_index(i:Int)
    {
        index = i;
        if (_parent != null)
        {
            _parent.remove(this);
            _parent.add(this);
        }
        return index;
    }
    function set_name(name:String)
    {
        if (_parent != null)
        {
            _parent._labels.remove(this.name);
            _parent._labels.set(name, this);
        }
        return this.name = name;
    }
    public static function fromJSON(frame:Frame)
    {
        if (frame == null) return null;

        var keyframe = new FlxKeyFrame(frame.I, frame.DU, frame.N);
        keyframe.colorEffect = AnimationData.fromColorJson(frame.C);

        if (frame.E != null)
        {
            for (element in frame.E)
            {
                keyframe.add(FlxElement.fromJSON(element));
            }
        }
        keyframe.filters = AnimationData.fromFilterJson(frame.F);

        return keyframe;
    }
}