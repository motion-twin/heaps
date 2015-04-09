package h2d.css;
import h2d.css.Defs;

class Rule {
	public var id : Int;
	public var c : CssClass;
	public var priority : Int;
	public var s : Style;
	public function new() {
	}
	
	public inline function toString(){
		return "CssRule {"+
			"id:"+id+"\n"+
			"c:"+c+"\n"+
			"priority:"+priority+"\n"
		+"}";
	}
}

@:access(h2d.comp.Component)
class Engine {

	var rules : Array<Rule>;

	public function new() {
		rules = [];
	}
	
	public inline function getRules() return rules;

	public function applyClasses( c : h2d.comp.Component ) {
		var s = new Style();
		c.style = s;
		var rules = [];
		for( r in this.rules ) {
			if( !ruleMatch(r.c, c) )
				continue;
			rules.push(r);
		}
		rules.sort(sortByPriority);
		for( r in rules )
			s.apply(r.s);
		if( c.customStyle != null )
			s.apply(c.customStyle);
	}
	
	public function traverseStyles( c : h2d.comp.Component , apply : Rule->Style->Void) {
		var rules = [];
		for( r in this.rules ) {
			if( !ruleMatch(r.c, c) )
				continue;
			rules.push(r);
		}
		rules.sort(sortByPriority);
		for( r in rules )
			apply(r,r.s);
		if( c.customStyle != null )
			apply(null,c.customStyle);
	}

	function sortByPriority(r1:Rule, r2:Rule) {
		var dp = r1.priority - r2.priority;
		return dp == 0 ? r1.id - r2.id : dp;
	}

	public static function ruleMatch( c : CssClass, d : h2d.comp.Component ) {
		if( c.pseudoClass != null ) {
			var pc = ":" + c.pseudoClass;
			var found = false;
			for( cc in d.classes )
				if( cc == pc ) {
					found = true;
					break;
				}
			if( !found )
				return false;
		}
		if( c.className != null ) {
			if( d.classes == null || d.classes.length ==0 )
				return false;
			var found = false;
			for( cc in d.classes )
				if( cc == c.className ) {
					found = true;
					break;
				}
			if( !found )
				return false;
		}
		if( c.node != null && c.node != d.name )
			return false;
		if( c.id != null && c.id != d.id )
			return false;
		if( c.parent != null ) {
			var p = d.parentComponent;
			while( p != null ) {
				if( ruleMatch(c.parent, p) )
					break;
				p = p.parentComponent;
			}
			if( p == null )
				return false;
		}
		return true;
	}

	public function addRules( text : String ) {
		for( r in new Parser().parseRules(text) ) {
			var c = r.c;
			var imp = r.imp ? 1 : 0;
			var nids = 0, nothers = 0, nnodes = 0;
			while( c != null ) {
				if( c.id != null ) nids++;
				if( c.node != null ) nnodes++;
				if( c.pseudoClass != null ) nothers++;
				if( c.className != null ) nothers++;
				c = c.parent;
			}
			var rule = new Rule();
			rule.id = rules.length;
			rule.c = r.c;
			rule.s = r.s;
			rule.priority = (imp << 24) | (nids << 16) | (nothers << 8) | nnodes;
			rules.push(rule);
		}
	}

}
