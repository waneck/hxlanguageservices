package haxe.languageservices.node;

enum Node {
    NId(value:String);
    NOp(value:String);
    NConst(value:Dynamic);
    NList(value:Array<ZNode>);
    NListDummy(value:Array<ZNode>);
    NIdList(value:Array<ZNode>);
    NConstList(items:Array<ZNode>);
    NPackage(fqName:ZNode);
    NImport(fqName:ZNode);
    NIf(cond:ZNode, trueExpr:ZNode, falseExpr:ZNode);
    NArray(items:Array<ZNode>);
    NObjectItem(key:ZNode, value:ZNode);
    NObject(items:Array<ZNode>);
    NBlock(items:Array<ZNode>);
    NFor(iteratorName:ZNode, iteratorExpr:ZNode, body:ZNode);

    NClass(name:ZNode, typeParams:ZNode, decls:ZNode);
    NTypedef(name:ZNode);
    NEnum(name:ZNode);

    NVar(name:ZNode, type:ZNode, value:ZNode);
    NFunction(name:ZNode, expr:ZNode);
    NContinue();
    NBreak();
    NReturn(?expr:ZNode);
    NAccess(node:ZNode);
    NCall(node:ZNode);
    NAccessList(node:ZNode, accessors:ZNode);
    NMember(modifiers:ZNode, decl:ZNode);
    NNew(id:ZNode, call:ZNode);
    NUnary(op:ZNode, value:ZNode);
    NIdWithType(id:ZNode, type:ZNode);
    NTypeParams(items:Array<ZNode>);
    NBinOpPart(op:ZNode, expr:ZNode);
    NFile(decls:Array<ZNode>);
}

