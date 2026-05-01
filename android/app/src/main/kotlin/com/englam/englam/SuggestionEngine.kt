package com.englam.englam

object SuggestionEngine {
    private val dictionary: Map<String, List<String>> = mapOf(
        "pinnallathe" to listOf("പിന്നല്ലാതെ", "Pinnallathe", "പിന്നല്ലാത"),
        "adipoli" to listOf("അടിപൊളി", "adipoli", "അടിപൊളീ"),
        "alle" to listOf("അല്ലെ", "alle", "അല്ലേ"),
        "namaskaram" to listOf("നമസ്കാരം", "namaskaram", "നമസ്കാരം"),
        "englam" to listOf("എംഗ്ലാം", "Englam", "എംഗ്ലം"),
        "manglish" to listOf("മംഗ്ലീഷ്", "Manglish", "മംഗ്ലിഷ്"),
        "hello" to listOf("ഹലോ", "hello", "ഹെലോ"),
        "kerala" to listOf("കേരളം", "kerala", "കേരള"),
        "malayalam" to listOf("മലയാളം", "malayalam", "മലയാലം"),
        "ajmal" to listOf("അജ്മൽ", "ajmal", "അജ്മാൽ"),
    )

    private val rules: List<Pair<Regex, String>> = listOf(
        Regex("zh") to "ഴ്",
        Regex("sh") to "ഷ്",
        Regex("ch") to "ച്",
        Regex("th") to "ത്",
        Regex("nj") to "ഞ്",
        Regex("ng") to "ങ്",
        Regex("ph") to "ഫ്",
        Regex("kh") to "ഖ്",
        Regex("gh") to "ഘ്",
        Regex("bh") to "ഭ്",
        Regex("dh") to "ധ്",
        Regex("jh") to "ഝ്",
        Regex("a") to "ാ",
        Regex("e") to "െ",
        Regex("i") to "ി",
        Regex("o") to "ൊ",
        Regex("u") to "ു",
        Regex("b") to "ബ്",
        Regex("c") to "ക്",
        Regex("d") to "ഡ്",
        Regex("f") to "ഫ്",
        Regex("g") to "ഗ്",
        Regex("h") to "ഹ്",
        Regex("j") to "ജ്",
        Regex("k") to "ക്",
        Regex("l") to "ല്",
        Regex("m") to "മ്",
        Regex("n") to "ന്",
        Regex("p") to "പ്",
        Regex("q") to "ക്യു",
        Regex("r") to "ര്",
        Regex("s") to "സ്",
        Regex("t") to "റ്റ്",
        Regex("v") to "വ്",
        Regex("w") to "വ്",
        Regex("x") to "ക്സ്",
        Regex("y") to "യ്",
        Regex("z") to "സ്",
    )

    fun getSuggestions(input: String, isMalayalamMode: Boolean): List<String> {
        val lower = input.trim().lowercase()
        if (lower.isEmpty()) return emptyList()

        if (!isMalayalamMode) {
            val cap = if (input.isEmpty()) input else input.substring(0, 1).uppercase() + input.substring(1).lowercase()
            return listOf(lower, cap, input.uppercase())
        }

        val out = LinkedHashSet<String>()
        fun push(v: String) {
            val t = v.trim()
            if (t.isNotEmpty()) out.add(t)
        }

        val exact = dictionary[lower]
        if (exact != null) {
            exact.forEach(::push)
            push(input)
            return out.toList()
        }

        for ((k, v) in dictionary) {
            if (k.startsWith(lower)) {
                v.forEach(::push)
                push(input)
                return out.toList()
            }
        }

        var transliterated = lower
        for ((re, rep) in rules) {
            transliterated = transliterated.replace(re, rep)
        }

        transliterated = transliterated
            .replaceFirst(Regex("^ാ"), "അ")
            .replaceFirst(Regex("^െ"), "എ")
            .replaceFirst(Regex("^ി"), "ഇ")
            .replaceFirst(Regex("^ൊ"), "ഒ")
            .replaceFirst(Regex("^ു"), "ഉ")

        push(transliterated)
        push("${transliterated}ം")
        push(input)
        return out.toList()
    }
}

