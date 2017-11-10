% this code regresses voxel-wise difference in variance and covariance pre
% and post retroicor against the difference in cardiac and respiratory
% spectral power pre and post retroicor. Only significant voxels with
% positive correlation (i.e., z>0, where z is Fisher transformed r,
% thresholded at FDR=0.05) are considered.
% The code uses the frequency bands identified manually on the cardiac
% pulsation and respiration signals using power_spectra.m.


basepath='/home/mkayvanrad/data/healthyvolunteer/processed/retroicorpipe/';
ndiscard=10;
TR=0.380; % seconds (for current fast EPI data)
obase='/home/mkayvanrad/Dropbox/Projects/Physiological Noise Correction/Publications/ISMRM 2017/Results/';

% output files
fout=fopen(strcat(obase,'varcovar_vs_power.csv'),'w');

fprintf(fout,'Subject, var_b_card, var_b_resp, var_r2, var_p, cov_b_card, cov_b_resp, cov_r2, cov_p\n');

%% compute relative poweres
fin=fopen('/home/mkayvanrad/Dropbox/Projects/Physiological Noise Correction/Publications/ISMRM 2017/Results/physio.csv');
% read the header
h=textscan(fin,'%s%s%s%s%s%s%s',1,'delimiter',',');
% read the rest
phys=textscan(fin,'%s%s%f%f%s%f%f','delimiter',',');

n=length(phys{1});

for i=1:n
    
    subject=cell2mat(phys{1}(i));
    
    preBOLDfile=strcat(basepath,subject,'/fepi/fepi_pipeline_noRet_slicetimer_mcflirt_brainExtractAFNI_ssmooth_3dFourier.nii.gz');
    postBOLDfile=strcat(basepath,subject,'/fepi/fepi_pipeline_slicetimer_mcflirt_brainExtractAFNI_ssmooth_3dFourier_retroicor.nii.gz');
    preSPMfile=strcat(basepath,subject,'/fepi/fepi_pipeline_noRet_slicetimer_mcflirt_brainExtractAFNI_ssmooth_3dFourier_z_thresh.nii.gz');
    postSPMfile=strcat(basepath,subject,'/fepi/fepi_pipeline_slicetimer_mcflirt_brainExtractAFNI_ssmooth_3dFourier_retroicor_z_thresh.nii.gz');
    precovfile=strcat(basepath,subject,'/fepi/fepi_pipeline_noRet_slicetimer_mcflirt_brainExtractAFNI_ssmooth_3dFourier_cov.nii.gz');
    postcovfile=strcat(basepath,subject,'/fepi/fepi_pipeline_slicetimer_mcflirt_brainExtractAFNI_ssmooth_3dFourier_retroicor_cov.nii.gz');
    prevarfile=strcat(basepath,subject,'/fepi/fepi_pipeline_noRet_slicetimer_mcflirt_brainExtractAFNI_ssmooth_3dFourier_var.nii.gz');
    postvarfile=strcat(basepath,subject,'/fepi/fepi_pipeline_slicetimer_mcflirt_brainExtractAFNI_ssmooth_3dFourier_retroicor_var.nii.gz');
    
    preBOLD_mri = MRIread(preBOLDfile);
    preBOLD=preBOLD_mri.vol;
    X=preBOLD_mri.width;
    Y=preBOLD_mri.height;
    Z=preBOLD_mri.depth;
    T=preBOLD_mri.nframes;
    
    postBOLD_mri = MRIread(postBOLDfile);
    postBOLD=postBOLD_mri.vol;
    
    preSPM_mri = MRIread(preSPMfile);
    preSPM=preSPM_mri.vol;    
    
    postSPM_mri = MRIread(postSPMfile);
    postSPM=postSPM_mri.vol;   
    
    precov_mri = MRIread(precovfile);
    precov=precov_mri.vol;    
    
    postcov_mri = MRIread(postcovfile);
    postcov=postcov_mri.vol;
    
    prevar_mri = MRIread(prevarfile);
    prevar=prevar_mri.vol;    
    
    postvar_mri = MRIread(postvarfile);
    postvar=postvar_mri.vol;
    
    %% compute frequency power spectra
    % discarding frames at the beginning
    preBOLD=preBOLD(:,:,:,ndiscard+1:end);
    postBOLD=postBOLD(:,:,:,ndiscard+1:end);
    % now compute voxel-wise fft
    F_pre=fft(preBOLD,[],4);
    F_post=fft(postBOLD,[],4);
    % now compute power at resp and card frequency bands
    fresp_min=phys{6}(i);
    fresp_max=phys{7}(i);
    fcard_min=phys{3}(i);
    fcard_max=phys{4}(i);

    l=size(F_pre,4);
    fs=1/TR;

    fresp_min_ind=ceil(fresp_min/(fs/2)*l/2);
    fresp_max_ind=ceil(fresp_max/(fs/2)*l/2);
    fcard_min_ind=ceil(fcard_min/(fs/2)*l/2);
    fcard_max_ind=ceil(fcard_max/(fs/2)*l/2);

    Presp_pre=sum(abs(F_pre(:,:,:,fresp_min_ind:fresp_max_ind)).^2,4)./sum(abs(F_pre).^2,4);
    Presp_post=sum(abs(F_post(:,:,:,fresp_min_ind:fresp_max_ind)).^2,4)./sum(abs(F_post).^2,4);
    Pcard_pre=sum(abs(F_pre(:,:,:,fcard_min_ind:fcard_max_ind)).^2,4)./sum(abs(F_pre).^2,4);
    Pcard_post=sum(abs(F_post(:,:,:,fcard_min_ind:fcard_max_ind)).^2,4)./sum(abs(F_post).^2,4);    
    
    %% compute deltas
    deltaPresp=Presp_post-Presp_pre;
    deltaPcard=Pcard_post-Pcard_pre;
    deltaVar=postvar-prevar;
    deltaCov=postcov-precov;
    deltaZ=postSPM-preSPM;
    
    
    % while here save the results in nifti files
    mriout=prevar_mri;
    %mriout.nframes=1;
    mriout.vol=Presp_pre;
    err = MRIwrite(mriout,strcat(basepath,subject,'/fepi/fepi_pipeline_noRet_slicetimer_mcflirt_brainExtractAFNI_ssmooth_3dFourier_Presp.nii.gz'),'float');    

    mriout.vol=Pcard_pre;
    err = MRIwrite(mriout,strcat(basepath,subject,'/fepi/fepi_pipeline_noRet_slicetimer_mcflirt_brainExtractAFNI_ssmooth_3dFourier_Pcard.nii.gz'),'float');    

    mriout.vol=Presp_post;
    err = MRIwrite(mriout,strcat(basepath,subject,'/fepi/fepi_pipeline_slicetimer_mcflirt_brainExtractAFNI_ssmooth_3dFourier_retroicor_Presp.nii.gz'),'float');    

    mriout.vol=Pcard_post;
    err = MRIwrite(mriout,strcat(basepath,subject,'/fepi/fepi_pipeline_slicetimer_mcflirt_brainExtractAFNI_ssmooth_3dFourier_retroicor_Pcard.nii.gz'),'float');    
    
    % only consider voxels where z>0
    deltaPresp=deltaPresp(preSPM>0 & postSPM>0);
    deltaPcard=deltaPcard(preSPM>0 & postSPM>0);
    deltaVar=deltaVar(preSPM>0 & postSPM>0);
    deltaCov=deltaCov(preSPM>0 & postSPM>0);
    deltaZ=deltaZ(preSPM>0 & postSPM>0);
    
    c=1.5;
    outlier= (deltaPresp > (quantile(deltaPresp,0.75) + c * iqr(deltaPresp)) | deltaPresp < (quantile(deltaPresp,0.25) - c * iqr(deltaPresp))) | ...
        (deltaPcard > (quantile(deltaPcard,0.75) + c * iqr(deltaPcard)) | deltaPcard < (quantile(deltaPcard,0.25) - c * iqr(deltaPcard))) | ...
        (deltaVar > (quantile(deltaVar,0.75) + c * iqr(deltaVar)) | deltaVar < (quantile(deltaVar,0.25) - c * iqr(deltaVar))) | ...
        (deltaCov > (quantile(deltaCov,0.75) + c * iqr(deltaCov)) | deltaCov < (quantile(deltaCov,0.25) - c * iqr(deltaCov)));
    
    samp=~outlier;
    deltaPresp=deltaPresp(samp);
    deltaPcard=deltaPcard(samp);
    deltaVar=deltaVar(samp);
    deltaCov=deltaCov(samp);
    
    %% regression
    
    lm_var=fitlm([deltaPcard,deltaPresp],deltaVar);
    lm_cov=fitlm([deltaPcard,deltaPresp],deltaCov);
    
    fprintf(fout,'%s,',subject);
    fprintf(fout,'%f,%f,%f,%f,',[lm_var.Coefficients.Estimate(2),lm_var.Coefficients.Estimate(3),lm_var.Rsquared.Ordinary,lm_var.coefTest]);
    fprintf(fout,'%f,%f,%f,%f\n',[lm_cov.Coefficients.Estimate(2),lm_cov.Coefficients.Estimate(3),lm_cov.Rsquared.Ordinary,lm_cov.coefTest]);
    
%     figure(i+40)
%     scatter3(deltaPcard,deltaPresp,deltaVar)
%     
%     
%     figure(i+60)
%     scatter3(deltaPcard,deltaPresp,deltaCov)
    
    
%     figure(i+20)
%     subplot(2,1,1)
%     lm_var.plot
%     %title('Var vs. Card & Resp Power')
%     axis tight
%     subplot(2,1,2)
%     lm_cov.plot
%     %title('Cov vs. Card & Resp Power')    
%     axis tight
    
    %% plot
    lm_var_card=fitlm(deltaPcard,deltaVar);
    figure(i)
    subplot(2,2,1)
    lm_var_card.plot
    legend('off')
    title('Var vs. Card Power')
    xlabel('')
    ylabel('dVar')
    axis tight
    
    lm_var_card=fitlm(deltaPresp,deltaVar);
    figure(i)
    subplot(2,2,2)
    lm_var_card.plot
    legend('off')
    title('Var vs. Resp Power')
    xlabel('')
    ylabel('')
    axis tight    

    lm_var_card=fitlm(deltaPcard,deltaCov);
    figure(i)
    subplot(2,2,3)
    lm_var_card.plot
    legend('off')
    title('Cov vs. Card Power')
    xlabel('dP')
    ylabel('dCov')
    axis tight
    
    lm_var_card=fitlm(deltaPresp,deltaCov);
    figure(i)
    subplot(2,2,4)
    lm_var_card.plot
    legend('off')
    title('Cov vs. Resp Power')
    xlabel('dP')
    ylabel('')
    axis tight    
    
end

fclose(fout);

