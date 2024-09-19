package fr.thomasbernard03.androidtools.commons.extensions

/**
 * Extension function to find the index of the Xth occurrence that matches the given predicate.
 *
 * @param predicate The predicate to test each element.
 * @param occurrence The occurrence number to find (1-based index).
 * @return The index of the Xth occurrence or -1 if not found.
 */
public inline fun <T> List<T>.indexOf(predicate: (T) -> Boolean, occurrence: Int): Int {
    require(occurrence > 0) { "Occurrence must be greater than 0" }

    var foundOccurences = 0
    for (index in this.indices) {
        if (predicate(this[index])) {
            foundOccurences++
            if (foundOccurences == occurrence) {
                return index
            }
        }
    }
    return -1 // If the Xth occurrence was not found
}