import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { AdbService } from 'src/providers/adb.service';
import { File } from 'src/models/file.interface';

@Component({
  selector: 'app-file-explorer',
  templateUrl: './file-explorer.component.html',
  styleUrls: ['./file-explorer.component.scss']
})
export class FileExplorerComponent implements OnInit {

  constructor(private adbService : AdbService, private changeDetector : ChangeDetectorRef) { }

  files : File[] | undefined = undefined

  ngOnInit(): void {
    this.adbService.getFiles().subscribe(files => {
      this.files = files
      console.log(files);
      this.changeDetector.detectChanges()
    })
  }

}
