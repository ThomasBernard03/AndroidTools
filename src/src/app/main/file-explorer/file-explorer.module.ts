import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FileExplorerComponent } from './file-explorer.component';
import { RouterModule, Routes } from '@angular/router';
import { FileExplorerItemComponent } from './file-explorer-item/file-explorer-item.component';

const routes: Routes = [
  {
    path: '',
    component: FileExplorerComponent,
  },
]

@NgModule({
  declarations: [
    FileExplorerComponent,
    FileExplorerItemComponent
  ],
  imports: [
    CommonModule,
    RouterModule.forChild(routes)
  ]
})
export class FileExplorerModule { }
