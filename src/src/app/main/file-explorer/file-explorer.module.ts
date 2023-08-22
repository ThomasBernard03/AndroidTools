import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FileExplorerComponent } from './file-explorer.component';
import { RouterModule, Routes } from '@angular/router';
import { FileExplorerFolderItemComponent } from './file-explorer-folder-item/file-explorer-folder-item.component';
import { FileExplorerFileItemComponent } from './file-explorer-file-item/file-explorer-file-item.component';

const routes: Routes = [
  {
    path: '',
    component: FileExplorerComponent,
  },
]

@NgModule({
  declarations: [
    FileExplorerComponent,
    FileExplorerFolderItemComponent,
    FileExplorerFileItemComponent
  ],
  imports: [
    CommonModule,
    RouterModule.forChild(routes)
  ]
})
export class FileExplorerModule { }
