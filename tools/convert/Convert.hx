import flash.Lib;
import flash.utils.ByteArray;
import hxd.fmt.h3d.AnimationWriter;
import hxd.fmt.h3d.Data;
import hxd.fmt.h3d.Tools;
import h3d.anim.Animation;
import h3d.mat.Material;
import h3d.mat.MeshMaterial;
import h3d.mat.Texture;
import h3d.scene.Scene;
import h3d.scene.Mesh;
import h3d.Vector;
import haxe.CallStack;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.Log;
import haxe.Serializer;
import haxe.Unserializer;

import hxd.BitmapData;
import hxd.ByteConversions;
import hxd.Pixels;
import hxd.Profiler;
import hxd.res.LocalFileSystem;
import hxd.System;

import format.png.Data;

using StringTools;

class Convert {
	
	var engine : h3d.Engine;
	var time : Float;
	var scene : Scene;
	
	var curFbx : h3d.fbx.Library = null;
	var animMode : h3d.fbx.Library.AnimationMode = h3d.fbx.Library.AnimationMode.LinearAnim;
	var anim : Animation = null;
	var saveAnimsOnly = false;
	var saveModelOnly = false; // no animations
	var verbose = #if debug true #else false #end;
	
	//todo change
	var makeAtlas = true;
	function new() {
		hxd.System.debugLevel = 0;
		start();
	}
	
	function start() {
		scene = new Scene();
		loadFbx();
	}
	
	function processArgs( args:Array<String>){
		var pathes = [];
		
		for ( i in 0...args.length ) {
			var arg = args[i].toLowerCase();
			switch(arg) {
				case "--mode": 
					var narg = args[i + 1].toLowerCase();
					switch(narg) {
						case "linear": animMode = h3d.fbx.Library.AnimationMode.LinearAnim;
						case "frame": animMode = h3d.fbx.Library.AnimationMode.FrameAnim;
					}
					
				case "--animations":
					saveAnimsOnly = true;
					
				case "--mesh":
					saveModelOnly = true;
					
				case "-v","--verbose":
					verbose = true;
					
				case "--make-atlas":
					makeAtlas = true;
					
					
				default: pathes.push( arg );
			}
		}
		
		return pathes;
	}
	
	function loadFbx(){
		var pathes = null;
		#if sys
		var args = Sys.args();
		if ( args.length < 1 ) {
			pathes = systools.Dialogs.openFile("Open .fbx to convert", "open", 
			{ count:1000, descriptions:[".fbx files"], extensions:["*.fbx", "*.FBX"] } );
			
		}
		else pathes = processArgs(args);
		#else
		pathes = [""];
		#end
		
		for ( path in pathes) {
			if(verbose) trace("Converting : " + path + "\n");
			
			#if sys
			var file = sys.io.File.getContent(path);
			#else
			var fref =  new flash.net.FileReference();
			fref.addEventListener(flash.events.Event.SELECT, function(_) fref.load());
			fref.addEventListener(flash.events.Event.COMPLETE, function(_){
			var file = (haxe.io.Bytes.ofData(fref.data)).toString();
			#end
				loadData(path,file);
				
				scene.traverse(function(obj) {
					trace("read " + obj.name);
					if ( obj.parent != null ) 
						trace("parent is :" + obj.parent.name);
				});
					
				
				//add filters or process here
				
				if (makeAtlas) {
					var allMat : Map<String,h3d.mat.Texture> = new Map();
					
					scene.traverse(function(obj:h3d.scene.Object) {
						if ( obj.isMesh()) {
							var m  = obj.toMesh();
							var name = m.material.texture.name;
							var tex = m.material.texture;
							allMat.set( name, tex );
							
							trace( "detected texture:"+name +" tex.width:"+tex.width);
						}
					});
						
					/*
					scene.traverse(function(obj) {
						if ( obj.isMesh()) {
							var m  = obj.toMesh();
							trace( m.material.name );
						}
					});
					*/
					
					if (false ) {
							/*
						var packer = new hxd.tools.Packer();
						var res : flash.display.BitmapData = packer.process();
						var bytes = hxd.ByteConversions.byteArrayToBytes(res.getPixels(res.rect));
						var out = new sys.io.BytesOutput(bytes);
						var w = new format.png.Writer( out  );
						w.write( format.png.Tools.build32ARGB(bytes));
						*/
					}
				}
				
				if( saveAnimsOnly )
					saveAnimation(path);
				else if( saveModelOnly )
					saveLibrary( path, false );
				else 
					saveLibrary( path, true );
						
				while (scene.childs.length > 0 )  scene.childs[0].remove();	
					
				curFbx = null;
			
			#if flash
			});
			fref.browse( [new flash.net.FileFilter("Kaydara ASCII FBX (*.FBX)", "*.FBX") ] );
			#end
		}
		
		return;
	}
	
	var bitmaps:Map<String,flash.display.BitmapData> = new Map();
	
	function loadData( path:String,data : String, newFbx = true ) {
		curFbx = new h3d.fbx.Library();
		var fbx = h3d.fbx.Parser.parse(data);
		curFbx.load(fbx);
		var frame = 0;
		var o : h3d.scene.Object = null;
		scene.addChild(o = curFbx.makeObject( function(str, mat) {
			var root = sys.FileSystem.fullPath(path);
			root = root.replace("\\", "/");
			var dir = root.split("/");
			dir.splice(dir.length - 1, 1);
			root = dir.join("/");
			str = root +"/" + str;
			if ( !sys.FileSystem.exists(str) ) {
				var m = h3d.mat.Texture.fromColor(0xFFFF00FF);
				m.name = str;
				return new MeshMaterial(m);
			}
			else {
				var bytes = sys.io.File.getBytes( str );
				var bi = new haxe.io.BytesInput(bytes);
				var data = new format.png.Reader( bi ).read();
				var header : format.png.Data.Header=null;
				for ( l in data) {
					switch(l) {
						case CHeader(h): header = h;
					default:
					}
				}
				var bmdBytes = format.png.Tools.extract32(data);
				var bmd = new flash.display.BitmapData(0,0,true);
				bmd.setPixels( new flash.geom.Rectangle(0, 0, header.width, header.height), hxd.ByteConversions.bytesToByteArray( bmdBytes ));
				var m = h3d.mat.Texture.fromBitmap(hxd.BitmapData.fromNative( bmd ));
				m.name = str;
				
				bitmaps.set( str, bmd );
				
				return new MeshMaterial(m);
			}
		}));
		setSkin(o);
		trace("loaded " + o.name);
	}
	
	function setSkin(obj:h3d.scene.Object) {
		anim = curFbx.loadAnimation(animMode);
		
		#if debug
		for( o in anim.objects){
			trace( "read anim of object:" + o.objectName+" "+o);
		}
		#end
		
		if ( anim != null ) anim = scene.getChildAt(0).playAnimation(anim);
		else throw "no animation found";
	}
	
	public function saveLibrary( path:String , saveAnims : Bool) {
		var o = scene.childs[0];
		if ( !saveAnims ) o.animations = [];
			
		var b;
		var a = new hxd.fmt.h3d.Writer( b=new haxe.io.BytesOutput() );
		a.write( o );
		
		var b = b.getBytes();
		if( saveAnims ) saveFile( b, "h3d.data", path );
		else 			saveFile( b, "h3d.model", path );
	}
	
	public function saveAnimation(path:String){
		var aData = anim.toData();
		
		var out = new haxe.io.BytesOutput();
		var builder = new hxd.fmt.h3d.AnimationWriter(out);
		builder.write(anim);
		var bytes = out.getBytes();
		
		saveFile( bytes, "h3d.anim", path);
	}
	
	public function saveFile(bytes:haxe.io.Bytes,ext:String,path:String) {
		var temp = path.split(".");
		temp.splice( temp.length - 1, 1);
		var outpath = temp.join(".") + ((temp.length<=1)?".":" ") +ext;
		
		#if windows 
		outpath = outpath.replace("/", "\\");
		#end
		
		#if flash
		var f = new flash.net.FileReference();
		var ser = Serializer.run(bytes.toString());
		f.save( ByteConversions.bytesToByteArray( bytes) );
		
		#elseif sys
		sys.io.File.saveBytes( outpath, bytes );
		#end
	}
	
	static function main() {
		
		#if flash
		haxe.Log.setColor(0xFF0000);
		#end
		
		new Convert();
		
		#if sys
		Sys.exit(0);
		#end
		return 0;
	}
	
}