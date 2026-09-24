# 코드 검토 메모

파일 내용을 기준으로 확인한 사항입니다.
공개용 정리에서는 인증정보 처리와 문서화를 변경했고 실습 로직은 일괄 수정하지 않았습니다.

| 위치 | 실행 전 확인·보완 사항 |
| --- | --- |
| minipro1/main.tf | aws_instance.user_data에 filebase64를 전달합니다. file() 또는 user_data_base64 사용으로 인코딩 방식을 맞춰야 합니다. |
| minipro1/main.tf | 인바운드 모든 프로토콜을 0.0.0.0/0에 허용합니다. 필요한 포트와 접속 원본으로 제한해야 합니다. |
| minipro1/linux-ssh-config.tpl | 실행 PC의 ~/.ssh/config에 접속 정보를 추가하므로 반복 실행 시 항목이 중복될 수 있습니다. |
| 03/elb-web-db/stage/services/outputs.tf | 참조하는 ALB가 하위 webserver-cluster 폴더에 있습니다. 출력 파일 위치와 리소스 구성을 맞춰야 합니다. |
| 02/data-source의 app/main.tf | ELB가 app_security_group_ids를 사용합니다. 외부 HTTP 접속 의도에 맞게 lb_security_group_ids 사용 여부를 확인해야 합니다. |
| 03/elb-web-db/global/s3/main.tf | 생성할 버킷을 backend로도 지정합니다. 새 환경에서는 버킷 선행 생성과 상태 이전 순서를 준비해야 합니다. |
| 03의 S3 설정 | 고정된 버킷 이름과 상태 key를 자신의 환경에 맞게 변경하고 force_destroy=true 사용도 검토해야 합니다. |
| 02/one-webserver-ext | 보안그룹 포트는 변수지만 웹서버 포트는 8080 고정입니다. 포트 변경 시 양쪽을 맞춰야 합니다. |
| 05/variable-loop-datasource/main.cf | .cf는 Terraform 구성으로 로드되지 않습니다. 수업 기록으로 보존합니다. |
| 05/variable-loop-datasource/variables.tf | 기본 VPC 대역이 190.160.0.0/16입니다. 의도한 대역인지 확인하고 필요하면 사설 대역으로 변경해야 합니다. |

## 구성과 동작 구분

- ASG의 최소·최대 규모 지정만으로 부하 기반 확장 정책을 구현한 것은 아닙니다.
- minipro2의 DB 두 대에는 복제·클러스터링 설정이 없습니다.
- 03·05 웹 템플릿의 DB 주소·포트 표시는 DB 접속 성공 증빙이 아닙니다.
- 일부 스크립트는 AMI에 BusyBox가 설치돼 있다고 가정합니다.
- 04의 S3 모듈에는 웹사이트 콘텐츠 업로드 리소스가 없습니다.
- Launch Configuration과 Launch Template 예제가 함께 있으므로 실습별 지원 환경을 확인해야 합니다.

실제 AWS 배포와 서비스 동작은 이번 정리에서 재검증하지 않았습니다.
