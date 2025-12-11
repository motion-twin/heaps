package h2d;

import h3d.Buffer;

private class QuadTileLayerContent extends h3d.prim.Primitive {

	var quads : Array<Float>;
	static var vertices : hxd.FloatBuffer = null;
	public var xMin : Float;
	public var yMin : Float;
	public var xMax : Float;
	public var yMax : Float;
	public var buffers : Array<Buffer>;

	var MAX_VERTICES : Int ;
	var MAX_QUADS : Int ;

	public function new() {
		MAX_VERTICES = 65532; // from vertexbuffer
		MAX_QUADS = MAX_VERTICES >> 2;
		if (vertices == null)
			vertices = new hxd.FloatBuffer(MAX_VERTICES * 8);
		clear();
	}

	override public function dispose()
	{
		super.dispose();
		if (buffers != null) {
			for (b in buffers) {
				b.dispose();
			}
		}
	}

	public function clear() {
		if (buffers != null) {
			for (b in buffers) {
				b.dispose();
			}
		}
		quads = new Array<Float>();
		xMin = hxd.Math.POSITIVE_INFINITY;
		yMin = hxd.Math.POSITIVE_INFINITY;
		xMax = hxd.Math.NEGATIVE_INFINITY;
		yMax = hxd.Math.NEGATIVE_INFINITY;
	}

	public function isEmpty() {
		return triCount() == 0;
	}

	override public function triCount() {
		return (quads.length >> 4) << 1;
	}

	public inline function addColor( x : Int, y : Int, color : h3d.Vector, t : Tile ) {
		add(x, y, color.r, color.g, color.b, color.a, t);
	}

	public function add( x : Int, y : Int, r : Float, g : Float, b : Float, a : Float, t : Tile ) {
		var sx = x + t.dx;
		var sy = y + t.dy;
		
		quads.push(sx);
		quads.push(sy);
		quads.push(sx + t.width);
		quads.push(sy);
		quads.push(sx);
		quads.push(sy + t.height);
		quads.push(sx + t.width);
		quads.push(sy + t.height);
		quads.push(t.u);
		quads.push(t.v);
		quads.push(t.u2);
		quads.push(t.v2);
		quads.push(r);
		quads.push(g);
		quads.push(b);
		quads.push(a);

		var x = x + t.dx, y = y + t.dy;
		if( x < xMin ) xMin = x;
		if( y < yMin ) yMin = y;
		x += t.width;
		y += t.height;
		if( x > xMax ) xMax = x;
		if( y > yMax ) yMax = y;
	}

	public function addTransform( x : Int, y : Int, sx : Float, sy : Float, r : Float, c : h3d.Vector, t : Tile ) {

		var ca = Math.cos(r), sa = Math.sin(r);
		var hx = t.width, hy = t.height;

		inline function updateBounds( x, y ) {
			if( x < xMin ) xMin = x;
			if( y < yMin ) yMin = y;
			if( x > xMax ) xMax = x;
			if( y > yMax ) yMax = y;
		}

		var dx1 = t.dx * sx;
		var dy1 = t.dy * sy;
		var dx2 = (t.dx + hx) * sx;
		var dy2 = (t.dy + hy) * sy;

		var px1 = dx1 * ca - dy1 * sa + x;
		var py1 = dy1 * ca + dx1 * sa + y;

		updateBounds(px1, py1);

		var px2 = dx2 * ca - dy1 * sa + x;
		var py2 = dy1 * ca + dx2 * sa + y;

		updateBounds(px2, py2);

		var px3 = dx1 * ca - dy2 * sa + x;
		var py3 = dy2 * ca + dx1 * sa + y;

		updateBounds(px3, py3);

		var px4 = dx2 * ca - dy2 * sa + x;
		var py4 = dy2 * ca + dx2 * sa + y;

		updateBounds(px4, py4);

		quads.push(px1);
		quads.push(py1);
		quads.push(px2);
		quads.push(py2);
		quads.push(px3);
		quads.push(py3);
		quads.push(px4);
		quads.push(py4);
		quads.push(t.u);
		quads.push(t.v);
		quads.push(t.u2);
		quads.push(t.v2);
		quads.push(c.r);
		quads.push(c.g);
		quads.push(c.b);
		quads.push(c.a);
	}

	override public function alloc(engine:h3d.Engine) {
		if( quads == null ) clear();
		buffers = new Array<Buffer>();
		var nQuads : Int = quads.length >> 4;

		var i : Int = 0;
		var j : Int = 0;
		var off : Int = 0;


		while( nQuads > 0 )
		{
			// convert to vertices format
			var n : Int = nQuads;
			if (n > MAX_QUADS)
				n = MAX_QUADS;

			i = 0;
			j = 0;

			var qx1 : Float;
			var qy1 : Float;
			var qx2 : Float;
			var qy2 : Float;
			var qx3 : Float;
			var qy3 : Float;
			var qx4 : Float;
			var qy4 : Float;
			var qu1 : Float;
			var qv1 : Float;
			var qu2 : Float;
			var qv2 : Float;
			var qr : Float;
			var qg : Float;
			var qb : Float;
			var qa : Float;

			while ((i>>4) < n)
			{
				qx1 = quads[off+i++]; 
				qy1 = quads[off+i++]; 
				qx2 = quads[off+i++]; 
				qy2 = quads[off+i++]; 
				qx3 = quads[off+i++]; 
				qy3 = quads[off+i++]; 
				qx4 = quads[off+i++]; 
				qy4 = quads[off+i++]; 
				qu1 = quads[off+i++]; 
				qv1 = quads[off+i++]; 
				qu2 = quads[off+i++]; 
				qv2 = quads[off+i++]; 
				qr  = quads[off+i++]; 
				qb  = quads[off+i++]; 
				qg  = quads[off+i++]; 
				qa  = quads[off+i++]; 

				vertices[j++] = qx1;
				vertices[j++] = qy1;
				vertices[j++] = qu1;
				vertices[j++] = qv1;
				vertices[j++] = qr;
				vertices[j++] = qg;
				vertices[j++] = qb;
				vertices[j++] = qa;

				vertices[j++] = qx2;
				vertices[j++] = qy2;
				vertices[j++] = qu2;
				vertices[j++] = qv1;
				vertices[j++] = qr;
				vertices[j++] = qg;
				vertices[j++] = qb;
				vertices[j++] = qa;
				
				vertices[j++] = qx3;
				vertices[j++] = qy3;
				vertices[j++] = qu1;
				vertices[j++] = qv2;
				vertices[j++] = qr;
				vertices[j++] = qg;
				vertices[j++] = qb;
				vertices[j++] = qa;
				
				vertices[j++] = qx4;
				vertices[j++] = qy4;
				vertices[j++] = qu2;
				vertices[j++] = qv2;
				vertices[j++] = qr;
				vertices[j++] = qg;
				vertices[j++] = qb;
				vertices[j++] = qa;
			}
			var b : h3d.Buffer = h3d.Buffer.ofSubFloats(vertices, 8, n << 2, [Quads, RawFormat]);
			buffers.push(b);
			nQuads -= n;
			off += n << 4;
		}
	}

	public inline function flush() {
		if (buffers == null)
			alloc(h3d.Engine.getCurrent());
		else {
			var disposed : Bool = false;
			for (b in buffers) {
				if (b.isDisposed()) {
						disposed = true;
				}
			}
			if (disposed) {
				for (b in buffers) {
					if (b.isDisposed() == false) {
							b.dispose();
					}
				}
				alloc(h3d.Engine.getCurrent());
			}

		}
	}

	public function doRender(engine:h3d.Engine) {
		flush();
		if( buffers != null) {
			var len : Int = triCount() * 2;
			var n : Int = len;
			for (b in buffers) {
				if (len > MAX_VERTICES)
					n = MAX_VERTICES;
				else
					n = len;
				engine.renderQuadBuffer(b);//, 0, n >> 1);
				len -= n;
			}
		}
	}

}

class QuadTileGroup extends Drawable {

	var content : QuadTileLayerContent;
	var curColor : h3d.Vector;

	public var tile : Tile;
	//public var rangeMin : Int;
	//public var rangeMax : Int;

	public function new(t : Tile, ?parent : h2d.Object) {
		super(parent);
		tile = t;
		//rangeMin = rangeMax = -1;
		curColor = new h3d.Vector(1, 1, 1, 1);
		content = new QuadTileLayerContent();
	}

	override function getBoundsRec( relativeTo : Object, out : h2d.col.Bounds, forSize : Bool ) {
		super.getBoundsRec(relativeTo, out, forSize);
		addBounds(relativeTo, out, content.xMin, content.yMin, content.xMax - content.xMin, content.yMax - content.yMin);
	}

	public function clear() : Void {
		content.clear();
	}

	/**
		If you want to add tiles after the GPU memory has been allocated (when the tilegroup with sync/displayed),
		make sure to call invalidate() first to force a refresh of your data.
	**/
	public function invalidate() : Void {
		content.dispose();
	}

	/**
		Returns the number of tiles added to the group
	**/
	public function count() : Int {
		return content.triCount() >> 1;
	}

	override function onRemove() {
		content.dispose();
		super.onRemove();
	}

	public function setDefaultColor( rgb : Int, alpha = 1.0 ) {
		curColor.x = ((rgb >> 16) & 0xFF) / 255;
		curColor.y = ((rgb >> 8) & 0xFF) / 255;
		curColor.z = (rgb & 0xFF) / 255;
		curColor.w = alpha;
	}

	public inline function add(x : Int, y : Int, t : h2d.Tile) {
		content.add(x, y, curColor.x, curColor.y, curColor.z, curColor.w, t);
	}

	public inline function addColor( x : Int, y : Int, r : Float, g : Float, b : Float, a : Float, t : Tile) {
		content.add(x, y, r, g, b, a, t);
	}

	public inline function addAlpha(x : Int, y : Int, a : Float, t : h2d.Tile) {
		content.add(x, y, curColor.x, curColor.y, curColor.z, a, t);
	}

	public inline function addTransform(x : Int, y : Int, sx : Float, sy : Float, r : Float, t : Tile) {
		content.addTransform(x, y, sx, sy, r, curColor, t);
	}

	override function draw(ctx:RenderContext) {
		drawWith(ctx,this);
	}


	override function sync( ctx : RenderContext ) {
		super.sync(ctx);
		// On some mobile GPU, uploading while rendering does create a lot of stall.
		// Let's make sure to force the upload before starting while we are still
		// syncing our 2d scene.
		content.flush();
	}

	@:allow(h2d)
	function drawWith( ctx:RenderContext, obj : Drawable ) {
		if (content.isEmpty())
			return;
		if( !ctx.beginDrawObject(obj, tile.getTexture()) ) return;
		content.doRender(ctx.engine);
	}

}
