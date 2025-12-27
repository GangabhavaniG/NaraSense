import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable({
  providedIn: 'root'
})
export class AuthService {

  API_URL = 'http://localhost:3000/api/v1/users/sign_in';

  constructor(private http: HttpClient) { }

  login(data: any) {
    return this.http.post(this.API_URL, { user: data });
  }
}
