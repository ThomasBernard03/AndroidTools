import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MainComponent } from './main.component';
import { RouterModule, Routes } from '@angular/router';


const routes: Routes = [
  {
    path: '',
    component: MainComponent,
    children : [
      { path: 'logcat', loadChildren:() => import('./logcat/logcat.module').then(x => x.LogcatModule)}
  ]},
]


@NgModule({
  declarations: [
    MainComponent
  ],
  imports: [
    CommonModule,
    RouterModule.forChild(routes),
  ]
})
export class MainModule { }
