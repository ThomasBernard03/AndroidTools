import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LogcatComponent } from './logcat.component';
import { RouterModule, Routes } from '@angular/router';
import { LogcatItemComponent } from './logcat-item/logcat-item.component';

const routes: Routes = [
  {
    path: '',
    component: LogcatComponent,
  },
]


@NgModule({
  declarations: [
    LogcatComponent,
    LogcatItemComponent
  ],
  imports: [
    CommonModule,
    RouterModule.forChild(routes)
  ],
  bootstrap: [LogcatComponent]
})
export class LogcatModule { }
