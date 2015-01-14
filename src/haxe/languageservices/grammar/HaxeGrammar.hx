package haxe.languageservices.grammar;

import haxe.languageservices.node.Reader;
import haxe.languageservices.node.Const;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.node.Node;
import haxe.languageservices.grammar.Grammar;
import haxe.languageservices.grammar.Grammar.Term;

class HaxeGrammar extends Grammar<Node> {
    public var ints:Term;
    public var fqName:Term;
    public var packageDecl:Term;
    public var importDecl:Term;
    public var usingDecl:Term;
    public var expr:Term;
    public var stm:Term;
    public var program:Term;
    
    private function buildNode(name:String): Dynamic -> Dynamic {
        return function(v) return Type.createEnum(Node, name, v);
    }

    private function buildNode2(name:String): Dynamic -> Dynamic {
        return function(v) return Type.createEnum(Node, name, [v]);
    }
    
    override private function simplify(znode:ZNode):ZNode {
        switch (znode.node) {
            case NAccessList(node, accessors):
                switch (accessors.node) {
                    case Node.NList([]): return node;
                    default:
                }
            default:
        }
        return znode;
    }
    
    private function operator(v:Dynamic):Term {
        return term(v, buildNode2('NOp'));
    }
    
    private function optError2(tok:String) {
        return optError(tok, 'expected $tok');
    }

    private function litS(z:String) return Term.TLit(z, function(v) return Node.NId(z));
    private function litK(z:String) return Term.TLit(z, function(v) return Node.NKeyword(z));

    public function new() {
        function rlist(v) return Node.NList(v);
        //function rlist2(v) return Node.NListDummy(v);


        var int = Term.TReg('int', ~/^\d+/, function(v) return Node.NConst(Const.CInt(Std.parseInt(v))));
        var identifier = Term.TReg('identifier', ~/^[a-zA-Z]\w*/, function(v) return Node.NId(v));
        fqName = list(identifier, '.', 1, false, function(v) return Node.NIdList(v));
        ints = list(int, ',', 1, false, function(v) return Node.NConstList(v));
        packageDecl = seq(['package', sure(), fqName, ';'], buildNode('NPackage'));
        importDecl = seq(['import', sure(), fqName, ';'], buildNode('NImport'));
        usingDecl = seq(['using', sure(), fqName, ';'], buildNode('NUsing'));
        expr = createRef();
        stm = createRef();
        //expr.term
        var ifExpr = seq(['if', sure(), '(', expr, ')', stm, opt(seqi(['else', stm]))], buildNode('NIf'));
        var forExpr = seq(['for', sure(), '(', identifier, 'in', expr, ')', stm], buildNode('NFor'));
        var whileExpr = seq(['while', sure(), '(', expr, ')', stm], buildNode('NWhile'));
        var doWhileExpr = seq(['do', sure(), stm, 'while', '(', expr, ')', optError2(';')], buildNode('NDoWhile'));
        var breakExpr = seq(['break', sure(), ';'], buildNode('NBreak'));
        var continueExpr = seq(['continue', sure(), ';'], buildNode('NContinue'));
        var returnExpr = seq(['return', sure(), opt(expr), ';'], buildNode('NReturn'));
        var blockExpr = seq(['{', list2(stm, 0, rlist), '}'], buildNode2('NBlock'));
        var parenExpr = seqi(['(', sure(), expr, ')']);
        var constant = any([ int, identifier ]);
        var type = createRef();
        var typeParamItem = type;
        var typeParamDecl = seq(['<', sure(), list(typeParamItem, ',', 1, false, rlist), '>'], buildNode2('NTypeParams'));

        var optType = opt(seq([':', sure(), type], identity));

        var typeName = seq([identifier, optType], buildNode('NIdWithType'));
        var typeNameList = list(typeName, ',', 0, false, rlist);
        
        setRef(type, any([
            identifier,
            seq([ '{', typeNameList, '}' ], rlist),
        ]));
        
        var varDecl = seq(['var', sure(), identifier, optType, opt(seqi(['=', expr])), optError(';', 'expected semicolon')], buildNode('NVar'));
        var objectItem = seq([identifier, ':', sure(), expr], buildNode('NObjectItem'));

        var arrayExpr = seq(['[', list(expr, ',', 0, true, rlist), ']'], buildNode2('NArray'));
        var objectExpr = seq(['{', list(objectItem, ',', 0, true, rlist), '}'], buildNode2('NObject'));
        var literal = any([ constant, arrayExpr, objectExpr ]);
        var unaryOp = any([operator('++'), operator('--'), operator('+'), operator('-')]);
        var binaryOp = any(['+', '-', '*', '/', '%', '==', '!=', '<', '>', '<=', '>=', '&&', '||']);
        var primaryExpr = createRef();
        
        var unaryExpr = seq([unaryOp, primaryExpr], buildNode("NUnary"));
        //var binaryExpr = seq([primaryExpr, binaryOp, expr], identity);
    
        var exprCommaList = list(expr, ',', 1, false, rlist);

        var arrayAccess = seq(['[', expr, ']'], buildNode('NAccess'));
        var fieldAccess = seq(['.', identifier], buildNode('NAccess'));
        var callPart = seq(['(', exprCommaList, ')'], buildNode('NCall'));
        var binaryPart = seq([binaryOp, expr], buildNode('NBinOpPart'));

        setRef(primaryExpr, any([
            parenExpr,
            unaryExpr,
            seq(['new', sure(), identifier, callPart], buildNode('NNew')),
            seq(
                [constant, list2(any([fieldAccess, arrayAccess, callPart, binaryPart]), 0, rlist)],
                buildNode('NAccessList')
            ),
        ]));

        setRef(expr, any([
            varDecl,
            ifExpr,
            forExpr,
            whileExpr,
            doWhileExpr,
            breakExpr,
            continueExpr,
            returnExpr,
            blockExpr,
            primaryExpr,
            literal,
        ]));

        setRef(stm, any([
            varDecl,
            ifExpr,
            forExpr,
            whileExpr,
            doWhileExpr,
            breakExpr,
            continueExpr,
            returnExpr,
            blockExpr,
            seq([primaryExpr, ';'], rlist),
            literal,
        ]));


        var memberModifier = any([litK('static'), litK('public'), litK('private'), litK('override')]);
        var functionDecl = seq(['function', sure(), identifier, '(', ')', expr], buildNode('NFunction'));
        var memberDecl = seq([opt(list2(memberModifier, 0, rlist)), any([varDecl, functionDecl])], buildNode('NMember'));
        
        var extendsDecl = seq(['extends', sure(), fqName, opt(typeParamDecl)], buildNode('NExtends'));
        var implementsDecl = seq(['implements', sure(), fqName, opt(typeParamDecl)], buildNode('NImplements'));
        
        var extendsImplementsList = list2(any([extendsDecl, implementsDecl]), 0, rlist);
        
        var classDecl = seq(
            ['class', sure(), identifier, opt(typeParamDecl), opt(extendsImplementsList), '{', list2(memberDecl, 0, rlist), '}'],
            buildNode('NClass')
        );
        var interfaceDecl = seq(
            ['interface', sure(), identifier, opt(typeParamDecl), opt(extendsImplementsList), '{', list2(memberDecl, 0, rlist), '}'],
            buildNode('NInterface')
        );
        var typedefDecl = seq(
            ['typedef', sure(), identifier, '=', type],
            buildNode('NTypedef')
        );

        var enumDecl = seq(
            ['enum', sure(), identifier, '{', '}'],
            buildNode('NEnum')
        );

        var typeDecl = any([classDecl, interfaceDecl, typedefDecl, enumDecl]);

        program = list2(any([packageDecl, importDecl, usingDecl, typeDecl]), 0, buildNode2('NFile'));
    }

    private var spaces = ~/^\s+/;
    //private var comments = ~/^\/\*(.*)\*\//;
    override private function skipNonGrammar(str:Reader) {
        //str.matchEReg(comments);
        str.matchEReg(spaces);
    }
}
