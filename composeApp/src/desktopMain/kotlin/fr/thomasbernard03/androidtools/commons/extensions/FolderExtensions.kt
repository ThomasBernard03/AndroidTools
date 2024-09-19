package fr.thomasbernard03.androidtools.commons.extensions

import fr.thomasbernard03.androidtools.domain.models.Folder

fun Folder.getParents() : List<Folder> {
    val parents = mutableListOf(this)
    var parent = this.parent

    while (parent != null) {
        parents.add(0, parent)
        parent = parent.parent
    }
    return parents
}