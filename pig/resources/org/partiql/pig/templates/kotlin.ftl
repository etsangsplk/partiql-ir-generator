[#ftl output_format="plainText"]
[#-- @ftlvariable name="universe" type="org.partiql.pig.generator.kotlin.KTypeUniverse" --]
[#-- @ftlvariable name="namespace" type="java.lang.String" --]
[#-- @ftlvariable name="generatedDate" type="java.time.OffsetDateTime" --]
[#-- Helpful links documenting Apache Freemarker:

Note:  the documentation shows directives wrapped in < > but we've configured it to use [ ] instead since
that seems cleaner when generating Kotlin code.

https://freemarker.apache.org/docs/dgui_template_overallstructure.html
https://freemarker.apache.org/docs/index.html

https://freemarker.apache.org/docs/dgui_misc_whitespace.html
--]
[#-- Generates a parameter list not including (). --]


[#macro parameter_list params]
[#list params as param]
[#if param.variadic]vararg [/#if]${param.kotlinName}: ${param.kotlinType}[#if param.defaultValue??] = ${param.defaultValue}[/#if],
[/#list]
metas: MetaContainer = emptyMetaContainer()
[/#macro]

[#-- Template to generate a tuple type class. --]
[#macro tuple t index]
class ${t.kotlinName}(
    [#list t.properties as p]
    val ${p.kotlinName}: ${p.kotlinTypeName},
    [/#list]
    override val metas: MetaContainer = emptyMetaContainer()
): ${t.superClass}() {

    override fun withMeta(metaKey: String, metaValue: Any): ${t.kotlinName} =
        ${t.kotlinName}(
            [#list t.properties as p]
            ${p.kotlinName} = ${p.kotlinName},
            [/#list]
            metas = metas + metaContainerOf(metaKey to metaValue))

[#if t.record]
    override fun toIonElement(): SexpElement {
        val elements = listOfNotNull(
            ionSymbol("${t.tag}"),
        [#list t.properties as p]
            ${p.kotlinName}?.let { ionSexpOf(ionSymbol("${p.tag}"), it.toIonElement()) }[#sep],[/#sep]
        [/#list]
        )

        return ionSexpOf(elements, metas = metas)
    }
[#else]
    override fun toIonElement(): SexpElement {
        val elements = ionSexpOf(
            ionSymbol("${t.tag}")[#rt]
[#list t.properties as p],
    [#if p.variadic]
            *${p.kotlinName}.map { it.toIonElement() }.toTypedArray()[#rt]
    [#else]
        [#if p.nullable]
            ${p.kotlinName}?.toIonElement() ?: ionNull()[#rt]
        [#else]
            ${p.kotlinName}.toIonElement()[#rt]
        [/#if][#rt]
    [/#if]
[/#list],
            metas = metas)
        return elements
    }
[/#if]

    override fun equals(other: Any?): Boolean {
        if (other == null) return false
        if (this === other) return true
        if (other.javaClass != ${t.kotlinName}::class.java) return false

        [#list t.properties]
        other as ${t.kotlinName}
        [#items as p]
        if (${p.kotlinName} != other.${p.kotlinName}) return false
        [/#items]
        [/#list]
        return true
    }

    [#list t.properties]
    private val myHashCode by lazy(LazyThreadSafetyMode.NONE) {
        [#items as p]
        [#if p?index == 0]var hc = [#else]hc = 31 * hc + [/#if]${p.kotlinName}.hashCode()
        [/#items]
        hc
    }

    override fun hashCode(): Int = myHashCode
    [#else]
    override fun hashCode(): Int = ${index?c}
    [/#list]
}

[/#macro]

[#--Emits builder functions that wraps the constructors of domain type. --]
[#macro builder_constructor_fun t return_type]
[#list t.builderFunctions as bf]
/**
 * Creates an instance of [${return_type}].
[#if bf.kotlinName?ends_with("_")]
 *
 * Use this variant when metas must be passed to primitive child elements.
 *
 * (The "_" suffix is needed to work-around conflicts due to type erasure and ambiguities with null arguments.)
[/#if]
 */
fun ${bf.kotlinName}(
    [@indent count=4]
        [@parameter_list bf.parameters/]
    [/@indent]
): ${return_type} =
    ${return_type}(
    [#list bf.constructorArguments as p]
        ${p.kotlinName} = ${p.value},
    [/#list]
        metas = metas)

[/#list]
[/#macro]

[#---------------------------------------------------------------------------
    Template output starts here
 ----------------------------------------------------------------------------]
/**
 * This code was generated by the PartiQL I.R. Generator.
 * Do not modify this file.  [#-- Unless you're editing the template, of course! --]
 */
@file:Suppress("unused", "MemberVisibilityCanBePrivate", "FunctionName",
    "CanBePrimaryConstructorProperty", "UNNECESSARY_SAFE_CALL",
    "USELESS_ELVIS", "RemoveRedundantQualifierName", "LocalVariableName")

package ${namespace}

import com.amazon.ionelement.api.*
import org.partiql.pig.runtime.*

[#list universe.domains as domain]
class ${domain.kotlinName} private constructor() {
[@indent count = 4]
/////////////////////////////////////////////////////////////////////////////
// Builder
/////////////////////////////////////////////////////////////////////////////
companion object {
    fun <T: ${domain.kotlinName}Node> build(block: Builder.() -> T) =
        Builder.block()

    fun transform(element: AnyElement): ${domain.kotlinName}Node =
        transform(element.asSexp())

    fun transform(element: SexpElement): ${domain.kotlinName}Node =
        Transformer().transform(element)
}

object Builder {
    [@indent count = 4]
        [#if domain.tuples?size > 0]
        // Tuples
        [#list domain.tuples as tuple]
        [@builder_constructor_fun tuple "${domain.kotlinName}.${tuple.kotlinName}"/]

        [/#list]
        [/#if]
        [#list domain.sums as s]
        [#-- Not sure why the [#lt] below is needed to emit the correct indentation. --]
        // Variants for Sum: ${s.kotlinName} [#lt]
        [#list s.variants as tuple]
        [@builder_constructor_fun tuple "${domain.kotlinName}.${s.kotlinName}.${tuple.kotlinName}"/]

        [/#list]
        [/#list]
    [/@indent]
}

/** Base class for all ${domain.kotlinName} types. */
abstract class ${domain.kotlinName}Node : DomainNode {
    override fun toString() = toIonElement().toString()
    abstract override fun withMeta(metaKey: String, metaValue: Any): ${domain.kotlinName}Node
    abstract override fun toIonElement(): SexpElement
}


[#if domain.tuples?size > 0]
/////////////////////////////////////////////////////////////////////////////
// Tuple Types
/////////////////////////////////////////////////////////////////////////////
[#list domain.tuples as p]
[@tuple p p?index /]
[/#list]
[/#if]

/////////////////////////////////////////////////////////////////////////////
// Sum Types
/////////////////////////////////////////////////////////////////////////////
[#list domain.sums as s]

sealed class ${s.kotlinName} : ${s.superClass}() {

[#list s.variants as v]
[@indent count=4]
    [@tuple t = v index = ((s?index + 1) * 1000 + v?index) /]
[/@indent]

[/#list]
}
[/#list]

/////////////////////////////////////////////////////////////////////////////
// Transformer
/////////////////////////////////////////////////////////////////////////////

[#macro transformer_case tuple domain_name]
    "${tuple.tag}" -> {
    [#if tuple.record]
        val ir = sexp.transformToIntermediateRecord()
        [#-- TODO:  support variadic fields --]

        [#list tuple.properties as p]
        val ${p.kotlinName} = ${p.transformExpr}
        [/#list]

        ir.malformedIfAnyUnprocessedFieldsRemain()

        ${tuple.constructorName}([#list tuple.properties as cp]${cp.kotlinName}, [/#list]metas = sexp.metas)
    [#else]
        sexp.requireArityOrMalformed(IntRange(#{tuple.arity.first}, #{tuple.arity.last}))
        [#list tuple.properties as p]
        val ${p.kotlinName} = ${p.transformExpr}
        [/#list]
        ${domain_name}.${tuple.constructorName}(
            [#list tuple.properties as p]
            ${p.kotlinName},
            [/#list]
            metas = sexp.metas)
    [/#if]
    }
[/#macro]

private class Transformer : IonElementTransformerBase<${domain.kotlinName}Node>() {

    override fun innerTransform(sexp: SexpElement): ${domain.kotlinName}Node {
        return when(sexp.tag) {
[#if domain.tuples?size > 0]
            //////////////////////////////////////
            // Tuple Types
            //////////////////////////////////////
[#list domain.tuples as t]
[@indent count = 8]
[@transformer_case t domain.kotlinName /]
[/@indent]
[/#list]
[/#if]
[#list domain.sums as s]
            //////////////////////////////////////
            // Variants for Sum Type '${s.kotlinName}'
            //////////////////////////////////////
[#list s.variants as v]
[@indent count = 8]
[@transformer_case v domain.kotlinName /]
[/@indent]
[/#list]
[/#list]
            else -> errMalformed(sexp.head.metas.location, "Unknown tag '${r"${sexp.tag}"}' for domain '${domain.tag}'")
        }
    }
}

[#include "kotlin-visitor.ftl"]
[#include "kotlin-visitor-fold.ftl"]
[#include "kotlin-visitor-transform.ftl"]

[/@indent]
}

[/#list]